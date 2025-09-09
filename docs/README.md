# Jailbot Watch Face Documentation

## Overview
Jailbot is an innovative Garmin Connect IQ watch face featuring a unique time display where the hour number orbits the watch rim based on the current minute position. This creates an intuitive and visually striking way to read time at a glance.

## Documentation Structure

### 📋 [TECHNICAL_SPEC.md](./TECHNICAL_SPEC.md)
Comprehensive technical specification covering:
- Architecture overview and component design
- API documentation for all modules
- Performance optimization guidelines
- Testing protocols and deployment process
- Implementation details and pseudocode examples

### 🔧 [../CLAUDE.md](../CLAUDE.md)
Development guidelines with ustad cognitive scaffolding:
- Mandatory verification workflows
- Bug fix and feature development protocols
- Testing and deployment checklists
- Known issues and solutions

## Quick Links

### For Developers
- [Component Specifications](./TECHNICAL_SPEC.md#2-component-specifications)
- [API Documentation](./TECHNICAL_SPEC.md#3-api-documentation)
- [Testing Guidelines](./TECHNICAL_SPEC.md#5-testing-guidelines)

### For Users
- **Unique Features**: Hour number circles the rim based on minutes
- **Simple Character**: Jailbot with natural blinking animations
- **AOD Support**: Optimized Ghost Jailbot for AMOLED displays
- **Device Support**: fenix 7 series and Forerunner 965

## Key Innovation

The watch face revolutionizes time display:
- **12:00** → Hour "12" at top (12 o'clock position)
- **12:15** → Hour "12" at right (3 o'clock position)
- **12:30** → Hour "12" at bottom (6 o'clock position)
- **12:45** → Hour "12" at left (9 o'clock position)

This creates an analog-inspired digital experience where time flows naturally around the watch face.

## Technical Highlights

### Performance
- < 20ms update cycle on MIP displays
- < 12ms target on AMOLED
- 70% pixel reduction in AOD mode
- Optimized battery usage with curated blink schedule

### Architecture
- **MonkeyC** implementation
- **7 modular components** for maintainability
- **Ustad-verified** development workflow
- **Atomic commit** philosophy

## Contributing

All contributions must follow the ustad verification workflow:
1. Check complexity before implementation
2. Verify claims with evidence
3. Test in simulator before deployment
4. Document patterns with gh-learn

See [CLAUDE.md](../CLAUDE.md) for detailed development protocols.

## Version History

- **v1.0** - Initial release with core time display and mood system
- Features 7 mood states, AOD support, and health metric integration

## License

Proprietary - Garmin Connect IQ Store Distribution

---

*For detailed technical information, see [TECHNICAL_SPEC.md](./TECHNICAL_SPEC.md)*