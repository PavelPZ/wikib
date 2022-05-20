export 'init.dart';

// export 'web.dart' // web implementation
//     if (dart.library.io) 'io.dart'; // non web implementation

export 'io.dart' // web implementation
    if (dart.library.html) 'web.dart'; // non web implementation
