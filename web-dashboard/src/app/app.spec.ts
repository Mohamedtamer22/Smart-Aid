import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [provideHttpClient()],
    }).compileComponents();
  });

  it('should create the Smart Aid ECC portal app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render ECC login header and all 9 demo role chips when unauthenticated', async () => {
    localStorage.clear();
    const fixture = TestBed.createComponent(App);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Emergency Command Center');
    const chips = compiled.querySelectorAll('.role-chip');
    expect(chips.length).toBe(9);
  });

  it('should classify semantic status badges, congestion levels, and filter incidents', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;

    expect(app.statusClass('COMPLETED')).toBe('status-success');
    expect(app.statusClass('EMS_ASSIGNED')).toBe('status-info');
    expect(app.statusClass('SEARCHING')).toBe('status-warning');
    expect(app.statusClass('CANCELLED')).toBe('status-critical');
    expect(app.congestionClass(25)).toBe('bar-green');
    expect(app.congestionClass(60)).toBe('bar-amber');
    expect(app.congestionClass(85)).toBe('bar-red');
    expect(app.asPercent(140)).toBe(100);
    expect(app.asPercent(-5)).toBe(0);

    app.liveIncidents.set([
      { id: '1111aaaa', emergencyType: 'CARDIAC', priority: 'CRITICAL', status: 'SEARCHING' },
      { id: '2222bbbb', emergencyType: 'MEDICAL', priority: 'STANDARD', status: 'EMS_ASSIGNED' },
    ]);
    app.incidentFilter.set('cardiac');
    expect(app.filteredIncidents().length).toBe(1);
    expect(app.filteredIncidents()[0]['id']).toBe('1111aaaa');
  });

  it('should route each operational role to its default portal tab and classify error banners cleanly', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;

    expect(app.defaultTabForRoles(['ADMIN'])).toBe('overview');
    expect(app.defaultTabForRoles(['EMS'])).toBe('overview');
    expect(app.defaultTabForRoles(['HOSPITAL'])).toBe('hospitals');
    expect(app.defaultTabForRoles(['PHARMACIST'])).toBe('pharmacy');
    expect(app.defaultTabForRoles(['BLOOD_BANK_STAFF'])).toBe('bloodbank');
    expect(app.defaultTabForRoles(['LAB_STAFF'])).toBe('providers');
    expect(app.defaultTabForRoles(['DOCTOR'])).toBe('providers');
    expect(app.defaultTabForRoles(['VOLUNTEER'])).toBe('overview');
    expect(app.defaultTabForRoles(['USER'])).toBe('overview');

    app.showBanner('Permission denied', 'error');
    expect(app.bannerTone()).toBe('error');
    expect(app.statusBanner()).toBe('Permission denied');

    expect(app.safeRoles(undefined)).toEqual([]);
    expect(app.safeRoles(['ADMIN', 'EMS'])).toEqual(['ADMIN', 'EMS']);
    expect(app.congestionClass(null)).toBe('bar-green');
  });
});
