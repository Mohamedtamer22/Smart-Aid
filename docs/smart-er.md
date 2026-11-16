# Smart ER

Smart ER ranks only verified hospitals that have a verified specialty match and a currently verified available required resource. Its current requirements are Cardiology/Cath Lab for cardiac events, Trauma/Trauma Bay for trauma or accidents, and Emergency/Emergency Bay otherwise.

For eligible hospitals:

```text
score = (travel × 0.30 + capability × 0.30 + specialty × 0.25 + congestion × 0.15) / total weights
```

Travel is normalized against the candidate set’s slowest estimated ETA; capability and specialty are 100 when verified; congestion is `100 - reported congestion`. Missing congestion yields zero positive congestion credit and is explicitly explained. ETA is transparent straight-line development estimation at 39 km/h, not live routing. No hospital is hardcoded as a winner, and an empty ranking is a valid result when verified evidence is absent.

The unit tests cover missing capability, unavailable congestion data, and changing weights. Sensitivity analysis and experimental export remain planned.
