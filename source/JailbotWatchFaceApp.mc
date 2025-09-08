using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class JailbotWatchFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new JailbotWatchFaceView() ];
    }

    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}