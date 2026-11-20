# Frame Performance Follow-up

The physical-device logs reported skipped frames (203, 56, 295, and 85) and a
`Davey! duration=1539ms` event. Investigate this as a separate UI/main-thread
performance task after Firebase authentication and profile provisioning have
been verified on a physical device. Do not disable Impeller based only on these
logs.
