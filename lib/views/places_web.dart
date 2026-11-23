import 'dart:js_interop';

@JS('inDriveSearchPlaces')
external JSPromise<JSString> _search(JSString query);

@JS('inDriveGetPlace')
external JSPromise<JSString> _getPlace(JSString id);

Future<String> searchPlacesWeb(String query) async =>
    (await _search(query.toJS).toDart).toDart;

Future<String> getPlaceWeb(String id) async =>
    (await _getPlace(id.toJS).toDart).toDart;
