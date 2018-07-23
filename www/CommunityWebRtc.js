var exec = require('cordova/exec');

// exports.coolMethod = function (arg0, success, error) {
//     exec(success, error, 'CommunityWebRtc', 'coolMethod', [arg0]);
// };

function CommunityWebRtc() {
    console.log("CommunityWebRtc.js: is created");
}

CommunityWebRtc.prototype.echo = function (arg0, success, error) {
    exec(success, error, 'CommunityWebRtc', 'echo', [arg0]);
};

CommunityWebRtc.prototype.getCallback = function (callback, success, error) {
    CommunityWebRtc.prototype.callbackResult = callback;
    exec(success, error, "CommunityWebRtc", 'callback', []);
}

// CALLBACK RESULT//
CommunityWebRtc.prototype.callbackResult = (payload) => {
    console.log("Received callbackResult", payload);
}

var communityWebRtc = new CommunityWebRtc();
module.exports = communityWebRtc;