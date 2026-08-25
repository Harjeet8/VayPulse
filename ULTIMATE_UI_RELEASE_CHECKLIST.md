# PhytoSense AI 9.0 — Brand Launch Release Checklist

This document maps the final product-polish brief to visible app behaviour. It
is also a quick verification sheet for the team before a competition demo.

## 30 product and interface upgrades

1. **Two experiences:** persistent Farmer Mode and Judge Mode.
2. **Farmer home:** briefing → health → next action → tools → optional detail.
3. **Health hero:** responsive ring, status and selected-zone context.
4. **ESP32 Live workspace:** one physical node, endpoint, freshness, validation,
   signal, battery and retry—with no simulated farm/location context.
5. **Live-value motion:** animated numbers and freshness pulse; both respect
   Reduce Motion.
6. **Guided camera flow:** crop → photo → evidence → result.
7. **Responsible crop screening:** crop confirmation, image-quality rejection,
   multimodal candidate ranking and no false claim of diagnosis accuracy.
8. **Explainable evidence:** visible photo, electrode, environmental and weather
   evidence plus a safe inspection step.
9. **Sensor cards:** values, previous-reading direction and preferred ranges.
10. **Historical intelligence:** selectable sensor and health trend charts.
11. **Farmer action system:** one prominent, plain-language next step.
12. **Smart alert center:** Action, Monitor, Resolved and System categories.
13. **Observation Timeline:** source-isolated readings, alerts, trials,
    calibration and simulation weather.
14. **Daily briefing:** current condition, readable explanation and alert count.
15. **Tamil/English guidance:** bilingual interface and text-to-speech actions.
16. **Responsive navigation:** bottom navigation on phones and navigation rail on
    wider browsers/desktops.
17. **Global command search:** Judge Mode search button and Ctrl+K desktop access.
18. **Unified design system:** shared spacing, cards, badges, typography and
    status colours.
19. **Field-ready dark mode:** deep-green surface hierarchy and readable status
    colours across cards, inputs, dialogs, menus and navigation.
20. **Accessibility controls:** larger text and reduced motion.
21. **Loading, empty and error states:** branded startup, actionable empty views
    and non-destructive failure guidance.
22. **Responsive onboarding:** scroll-safe pages and experience selection.
23. **Contextual guidance:** preferred ranges, tooltips, evidence descriptions
    and model-card limitations.
24. **Organized settings:** experience, source, ESP32, language, About,
    appearance, accessibility and demo controls.
25. **Live location and weather:** permission-on-action GPS, Tamil Nadu place
    names including Tiruchirappalli (Trichy), manual coordinates and cache.
26. **Offline-first records:** local queue, status/history and configurable later
    synchronization.
27. **Transparent impact estimator:** Indian rupee projection with editable
    assumptions and a clear non-guarantee statement.
28. **Presentation Mode 2.0:** resettable guided story and a one-screen current
    system snapshot.
29. **Judge evidence workflow:** system X-ray, calibration, controlled trials,
    farmer outcomes and one-tap evidence report.
30. **Trust and safety:** DEMO/LIVE labelling, source isolation, range validation,
    uncertainty language, farmer confirmation and no invented chemical dose.

## 31. Small details that make it feel real

- Custom launcher icon, branded splash/startup and consistent **PhytoSense AI**
  product naming across Android, iOS, web and desktop runners.
- Haptics for important source, mode and crop-selection actions on supported
  mobile devices.
- Pull-to-refresh on the farmer dashboard and ESP32 Live workspace.
- Swipe-to-archive alerts with Undo; confirmation before clearing an alert
  session; saved evidence is protected.
- Human-readable date/time and Indian rupee/number formatting where financial
  values are shown.
- Tamil-aware wrapping, scroll-safe onboarding and vertical settings choices.
- Desktop tooltips, Alt+1…5 tab navigation and Ctrl+K command search.
- Indexed tab stacks preserve navigation and scroll state.
- Responsive browser breakpoints, larger-text mode and flexible cards prevent
  clipped content at narrow widths and increased text scaling.
- Bottom sheets are scroll-safe; health rings have dedicated responsive space;
  SafeArea and page bottom padding protect actions from system/browser controls.
- Success, validation, archive, Undo and connection failures use consistent
  Material snackbars and status treatments.

## Final local SDK verification

Run on the presentation machine after extracting the ZIP:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Also inspect Farmer Mode, Judge Mode, dark mode, Tamil, larger text, Demo source
and ESP32 source before publishing or presenting.
