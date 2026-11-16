import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { tap } from 'rxjs/operators';
import { throwError } from 'rxjs';

export interface AuthUser {
  id: string;
  email: string;
  displayName: string;
  roles: string[];
}

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresInSeconds: number;
  user: AuthUser;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  readonly apiBase = 'http://localhost:8080';
  private readonly storageKey = 'smartaid_ecc_session_v1';

  readonly session = signal<TokenResponse | null>(this.loadStoredSession());
  readonly isAuthenticated = computed(() => this.session() !== null);
  readonly currentUser = computed(() => this.session()?.user ?? null);
  readonly roles = computed(() => this.session()?.user.roles ?? []);

  constructor(private readonly http: HttpClient) {}

  login(email: string, password: string) {
    return this.http
      .post<TokenResponse>(`${this.apiBase}/api/auth/login`, { email, password })
      .pipe(
        tap((res) => {
          this.session.set(res);
          localStorage.setItem(this.storageKey, JSON.stringify(res));
        }),
      );
  }

  refreshToken() {
    const current = this.session();
    if (!current?.refreshToken) {
      return throwError(() => new Error('No refresh token available'));
    }
    return this.http
      .post<TokenResponse>(`${this.apiBase}/api/auth/refresh`, {
        refreshToken: current.refreshToken,
      })
      .pipe(
        tap((res) => {
          this.session.set(res);
          localStorage.setItem(this.storageKey, JSON.stringify(res));
        }),
      );
  }

  logout(): void {
    const refreshToken = this.session()?.refreshToken;
    if (refreshToken) {
      this.http
        .post(`${this.apiBase}/api/auth/logout`, { refreshToken })
        .subscribe({ error: () => {} });
    }
    this.session.set(null);
    localStorage.removeItem(this.storageKey);
  }

  accessToken(): string | null {
    return this.session()?.accessToken ?? null;
  }

  hasAnyRole(...required: string[]): boolean {
    const userRoles = this.roles();
    return required.some((r) => userRoles.includes(r));
  }

  private loadStoredSession(): TokenResponse | null {
    try {
      const raw = localStorage.getItem(this.storageKey);
      return raw ? (JSON.parse(raw) as TokenResponse) : null;
    } catch {
      return null;
    }
  }
}
