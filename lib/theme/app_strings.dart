/// All user-facing copy for Sprout Focus lives here so the plant/garden voice
/// is consistent and easy to audit in one place.
class AppStrings {
  AppStrings._();

  static const String appName = 'Sprout Focus';
  static const String tagline = 'Grow focus, lock distractions';

  // Garden / home
  static const String gardenTab = 'Garden';
  static const String statsTab = 'Stats';
  static const String settingsTab = 'Settings';
  static const String brandBadge = 'SPROUT FOCUS';
  static const String plantCta = '🌱 PLANT A SESSION';
  static const String planting = 'PLANTING…';
  static const String searchingDevice = 'Looking for your planter…';
  static const String lockerNotFoundTitle = 'Planter Not Found';
  static const String lockerNotFoundBody =
      'We couldn\'t find a Sprout Focus planter nearby. '
      'Want to grow a simulated session without the device?';
  static const String growWithoutDevice = 'Grow Without Planter';
  static const String cancel = 'Cancel';

  // Focus session
  static const String setDuration = '🌱 Set your growth duration';
  static const String focusPrompt = 'What are you growing time for?';
  static const String addNote = '+ Add a note';
  static const String noteHint = 'What are you working on?';
  static const String startSession = 'PLANT & LOCK';
  static const String growingChip = 'GROWING';
  static const String timeUntilBloom = '🌿 Time until bloom';
  static const String stopGrowing = 'GROWING…';
  static const String bloomTitle = '🌸 IT BLOOMED!';
  static const String bloomBody = 'Beautiful focus! Returning to the planter…';
  static const String youGrewA = 'You grew a';
  static const String newSpecies = 'NEW SPECIES';
  static const String recapMinutes = 'minutes';
  static const String recapStreak = 'day streak';
  static const String recapSpecies = 'species';
  static const String waitingDevice = 'Waiting for the planter…';

  // Auth
  static const String joinTitle = 'Start Your Garden';
  static const String createAccountHeadline = 'PLANT YOUR\nFIRST SEED';
  static const String createAccountSub = 'Grow a focused routine';
  static const String aquaticAccountReplaced = createAccountHeadline;

  // Settings
  static const String settingsSub = 'Tend your focus garden';

  // Collection
  static const String collectionTitle = 'Your Collection';
  static const String collectionSub = 'Plants you have grown';
  static const String collectionLocked = 'Not yet grown';
  static const String viewCollection = 'View collection';

  // Onboarding
  static const String introSkip = 'Skip';
  static const String introNext = 'Next';
  static const String introStart = 'START GROWING';
  static const String replayTutorial = 'Replay tutorial';
  static const String demoModeLabel = 'Demo mode';
  static const String demoModeHelp =
      'Grow simulated sessions without the planter. Sessions run faster so a '
      'plant blooms in seconds — useful for demos.';

  // Tags (shared across setup / stats / history)
  static const List<String> tags = [
    'studying',
    'work',
    'reading',
    'exercise',
    'meditation',
    'other',
  ];
}
