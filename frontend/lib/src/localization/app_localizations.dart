import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static List<Locale> get supportedLocales => const [
        Locale('en'),
        Locale('ro'),
      ];

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  Future<bool> load() async {
    final jsonString = await rootBundle
        .loadString('assets/localization/app_${locale.languageCode}.arb');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    
    try {
      final userManualString = await rootBundle
          .loadString('assets/localization/user_manual_${locale.languageCode}.arb');
      final Map<String, dynamic> userManualMap = json.decode(userManualString);
      _localizedStrings.addAll(
        userManualMap.map((key, value) => MapEntry(key, value.toString())),
      );
    } catch (e) {
    }
    
    try {
      final modelInfoString = await rootBundle
          .loadString('assets/localization/model_info_${locale.languageCode}.arb');
      final Map<String, dynamic> modelInfoMap = json.decode(modelInfoString);
      _localizedStrings.addAll(
        modelInfoMap.map((key, value) => MapEntry(key, value.toString())),
      );
    } catch (e) {
    }
    
    return true;
  }

  String translate(String key) => _localizedStrings[key] ?? '**$key**';

  String get appTitle => _localizedStrings['appTitle'] ?? 'Vehicle Counter';
  String get uploadVideo => _localizedStrings['uploadVideo'] ?? 'Upload video';
  String get drawDirections => _localizedStrings['drawDirections'] ?? 'Draw directions';
  String get pickVideo => _localizedStrings['pickVideo'] ?? 'Pick Video';
  String get addDirection => _localizedStrings['addDirection'] ?? 'Add Direction';
  String get saveIntersection => _localizedStrings['saveIntersection'] ?? 'Save Intersection';
  String get loadIntersection => _localizedStrings['loadIntersection'] ?? 'Load Intersection';
  String get from => _localizedStrings['from'] ?? 'From';
  String get to => _localizedStrings['to'] ?? 'To';
  String get save => _localizedStrings['save'] ?? 'Save';
  String get delete => _localizedStrings['delete'] ?? 'Delete';
  String get start => _localizedStrings['start'] ?? 'Start';
  String get sendToBackend => _localizedStrings['sendToBackend'] ?? 'Start counting!';
  String get locked => _localizedStrings['locked'] ?? 'Locked';
  String get editable => _localizedStrings['editable'] ?? 'Editable';
  String get settings => _localizedStrings['settings'] ?? 'Settings';
  String get theme => _localizedStrings['theme'] ?? 'Theme';
  String get language => _localizedStrings['language'] ?? 'Language';
  String get directionLabel => _localizedStrings['directionLabel'] ?? 'Direction';
  String get pickAColor => _localizedStrings['pickAColor'] ?? 'Pick a color';
  String get cancel => _localizedStrings['cancel'] ?? 'Cancel';
  String get directionError => _localizedStrings['directionError'] ?? 'Direction Error';
  String get pleaseDrawDirection => _localizedStrings['pleaseDrawDirection'] ?? 'Please draw a direction on the canvas first.';
  String get error => _localizedStrings['error'] ?? 'Error';
  String get noDirectionSelected => _localizedStrings['noDirectionSelected'] ?? 'No direction selected.';
  String get waitingForServer => _localizedStrings['waitingForServer'] ?? 'Waiting for server...';
  String get userManual => _localizedStrings['userManual'] ?? 'User manual';
  String get userManualIntro => _localizedStrings['userManualIntro'] ?? 'Follow these steps to get started:';
  String get userManualStepUpload => _localizedStrings['userManualStepUpload'] ?? 'Click the canvas or upload button to select a video.';
  String get userManualStepWait => _localizedStrings['userManualStepWait'] ?? 'Wait while the server prepares the thumbnail.';
  String get userManualStepDraw => _localizedStrings['userManualStepDraw'] ?? 'Click to add points on the image to create direction lines, add labels, and lock them.';
  String get userManualStepSend => _localizedStrings['userManualStepSend'] ?? 'Send the locked directions to the backend.';
  String get userManualTip => _localizedStrings['userManualTip'] ?? 'Tip: You can change colors before drawing a new direction.';
  String get userManualEditingLine => _localizedStrings['userManualEditingLine'] ?? "You can edit a line's coordinates by selecting it, choosing a coordinate point (select in the direction card), and use WASD. The keys W and S move Y coordinates up and down, while A and D move X coordinates left and right.";
  String get uploadVideoToStartDrawingDirections => _localizedStrings['uploadVideoToStartDrawingDirections'] ?? 'Upload a video to start drawing directions';
  String get directionWarning => _localizedStrings['directionWarning'] ?? 'Direction must have at least 2 points';
  String get intersectionName => _localizedStrings['intersectionName'] ?? 'Intersection Name';
  String get intersectionNameHint => _localizedStrings['intersectionNameHint'] ?? 'e.g. Main St – Morning';
  String get noSavedIntersectionsFound => _localizedStrings['noSavedIntersectionsFound'] ?? 'No saved intersections found.';
  String get close => _localizedStrings['close'] ?? 'Close';
  String get appDescription => _localizedStrings['appDescription'] ?? 'Direction-aware vehicle counting with quick drawing and YOLO-ready pipelines.';
  String get results => _localizedStrings['results'] ?? 'Results';
  String get howToChooseModel => _localizedStrings['howToChooseModel'] ?? 'How to Choose the Right Model for Your Hardware';
  String get yolo11VersionLabel => _localizedStrings['yolo11VersionLabel'] ?? 'YOLO 11 version';
  String get modelYolo11Official => _localizedStrings['modelYolo11Official'] ?? 'YOLO11 (official pretrained)';
  String get loadFromDisk => _localizedStrings['loadFromDisk'] ?? 'Load from Disk';
  String get invalidFileContent => _localizedStrings['invalidFileContent'] ?? 'Invalid file content. Please select a valid intersection JSON file.';
  String get twoLinesRequired => _localizedStrings['twoLinesRequired'] ?? 'Direction is defined by two lines! Edit current lines or start a new direction';

  String get modelInfoTitle => _localizedStrings['modelInfoTitle'] ?? 'How to Choose the Right Model for Your Hardware';
  String get modelYolo11n => _localizedStrings['modelYolo11n'] ?? 'YOLO11n';
  String get modelYolo11s => _localizedStrings['modelYolo11s'] ?? 'YOLO11s';
  String get modelYolo11m => _localizedStrings['modelYolo11m'] ?? 'YOLO11m';
  String get modelYolo11l => _localizedStrings['modelYolo11l'] ?? 'YOLO11l';
  String get modelYolo11xl => _localizedStrings['modelYolo11xl'] ?? 'YOLO11xl';
  String get speedLabel => _localizedStrings['speedLabel'] ?? 'Speed:';
  String get accuracyLabel => _localizedStrings['accuracyLabel'] ?? 'Accuracy:';
  String get hardwareLabel => _localizedStrings['hardwareLabel'] ?? 'Hardware:';
  String get speedFastest => _localizedStrings['speedFastest'] ?? 'Fastest';
  String get speedFast => _localizedStrings['speedFast'] ?? 'Fast';
  String get speedMedium => _localizedStrings['speedMedium'] ?? 'Medium';
  String get speedSlow => _localizedStrings['speedSlow'] ?? 'Slow';
  String get speedVerySlow => _localizedStrings['speedVerySlow'] ?? 'Very Slow';
  String get accuracyGood => _localizedStrings['accuracyGood'] ?? 'Good';
  String get accuracyBetter => _localizedStrings['accuracyBetter'] ?? 'Better';
  String get accuracyVeryGood => _localizedStrings['accuracyVeryGood'] ?? 'Very Good';
  String get accuracyExcellent => _localizedStrings['accuracyExcellent'] ?? 'Excellent';
  String get accuracyOutstanding => _localizedStrings['accuracyOutstanding'] ?? 'Outstanding';
  String get hardwareMinimal => _localizedStrings['hardwareMinimal'] ?? 'Minimal (suitable for edge devices, mobile, CPU)';
  String get hardwareLow => _localizedStrings['hardwareLow'] ?? 'Low (suitable for CPU and older GPUs)';
  String get hardwareMedium => _localizedStrings['hardwareMedium'] ?? 'Medium (suitable for modern GPUs)';
  String get hardwareHigh => _localizedStrings['hardwareHigh'] ?? 'High (suitable for high-end GPUs)';
  String get hardwareVeryHigh => _localizedStrings['hardwareVeryHigh'] ?? 'Very High (suitable for premium hardware)';
  String get descriptionYolo11n => _localizedStrings['descriptionYolo11n'] ?? 'The nano model is the smallest and fastest. Use this if you have limited hardware resources or need real-time processing on mobile or IoT devices.';
  String get descriptionYolo11s => _localizedStrings['descriptionYolo11s'] ?? 'The small model offers a good balance between speed and accuracy. Recommended for laptops with limited GPU memory (2-4GB VRAM).';
  String get descriptionYolo11m => _localizedStrings['descriptionYolo11m'] ?? 'The medium model is the most balanced option. Recommended for laptops with dedicated GPUs (4-6GB VRAM) or desktop computers.';
  String get descriptionYolo11l => _localizedStrings['descriptionYolo11l'] ?? 'The large model offers high accuracy with slower processing. Recommended for high-performance GPUs (8GB+ VRAM) or batch processing.';
  String get descriptionYolo11xl => _localizedStrings['descriptionYolo11xl'] ?? 'The extra-large model provides the best accuracy but requires significant computational resources. Recommended for high-end GPUs (12GB+ VRAM) or server environments.';
  String get recommendationsTitle => _localizedStrings['recommendationsTitle'] ?? '💡 Recommendations:';
  String get recommendation1 => _localizedStrings['recommendation1'] ?? '• Start with YOLO11n or YOLO11s if unsure about your hardware capabilities';
  String get recommendation2 => _localizedStrings['recommendation2'] ?? '• If processing is too slow, downgrade to a smaller model';
  String get recommendation3 => _localizedStrings['recommendation3'] ?? '• If accuracy is not good enough, upgrade to a larger model';
  String get recommendation4 => _localizedStrings['recommendation4'] ?? '• GPU acceleration significantly improves speed (CUDA for NVIDIA, Metal for Apple)';
  String get tapCanvasToUpload => _localizedStrings['tapCanvasToUpload'] ?? 'Tap the canvas or button to upload a video';
  String get modelInfoTooltip => _localizedStrings['modelInfoTooltip'] ?? 'Click for more information about models';
  String get startScreenWelcome => _localizedStrings['startScreenWelcome'] ?? 'Welcome to VCount!';
  String get labelsAndLineRequired => _localizedStrings['labelsAndLineRequired'] ?? 'From / To labels required and draw at least one line.';
  String get line => _localizedStrings['line'] ?? 'Line';
  String get lines => _localizedStrings['lines'] ?? 'Lines';
  
  String lineNumber(int number) => '${line} ${number}';
  String linesCount(int count) => '${lines} (${count}):';
  String intersectionSaved(String name) => _localizedStrings['intersectionSaved']?.replaceAll('{name}', name) ?? 'Intersection "$name" saved in intersections folder!';
  String intersectionLoaded(String name) => _localizedStrings['intersectionLoaded']?.replaceAll('{name}', name) ?? 'Intersection "$name" loaded!';
  String intersectionDeleted(String name) => _localizedStrings['intersectionDeleted']?.replaceAll('{name}', name) ?? 'Intersection "$name" deleted!';
  String lineWithNumber(int number) => _localizedStrings['lineWithNumber']?.replaceAll('{number}', number.toString()) ?? 'Line {number}';
  String exitLineLabel(int number) => _localizedStrings['exitLineLabel']?.replaceAll('{number}', number.toString()) ?? 'Exit Line {number}';
  String entryLineLabel(int number) => _localizedStrings['entryLineLabel']?.replaceAll('{number}', number.toString()) ?? 'Entry Line {number}';

}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ro'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    if (old is _AppLocalizationsDelegate) {
      return true;
    }
    return false;
  }
}