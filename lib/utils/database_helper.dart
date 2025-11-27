/// Database helper that conditionally imports the correct implementation
/// based on the platform (web or mobile)
export 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper_mobile.dart'
    if (dart.library.html) 'database_helper_web.dart';