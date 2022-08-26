(function(window, undefined) {
  var dictionary = {
    "17911ee8-99c6-4132-9d24-b397deeaace2": "Following",
    "a70d6c07-48c0-47ed-b39c-081abf0af86b": "User Profile",
    "65041cbb-d91b-43eb-ac7b-8126f4505ddd": "Feed",
    "bf421439-6f91-4569-9369-cd3ee4a7a051": "Create Post",
    "af332831-aff6-4129-a070-03ea54f041b8": "Create Comment",
    "91020bc2-8138-421a-916e-52a885016edd": "Edit Profile",
    "d12245cc-1680-458d-89dd-4f0d7fb22724": "Loading",
    "99908925-8faa-4afc-bfcd-17a8ed6f9062": "Followers",
    "0c56c401-7e3c-43da-b796-0150815aaea4": "Comments",
    "38a4a1db-a449-4317-931a-dd30c94e046d": "My Profile",
    "f39803f7-df02-4169-93eb-7547fb8c961a": "Template 1",
    "475b52c0-998f-4f37-ae2e-07910ed82cc8": "l",
    "bb8abf58-f55e-472d-af05-a7d1bb0cc014": "default"
  };

  var uriRE = /^(\/#)?(screens|templates|masters|scenarios)\/(.*)(\.html)?/;
  window.lookUpURL = function(fragment) {
    var matches = uriRE.exec(fragment || "") || [],
        folder = matches[2] || "",
        canvas = matches[3] || "",
        name, url;
    if(dictionary.hasOwnProperty(canvas)) { /* search by name */
      url = folder + "/" + canvas;
    }
    return url;
  };

  window.lookUpName = function(fragment) {
    var matches = uriRE.exec(fragment || "") || [],
        folder = matches[2] || "",
        canvas = matches[3] || "",
        name, canvasName;
    if(dictionary.hasOwnProperty(canvas)) { /* search by name */
      canvasName = dictionary[canvas];
    }
    return canvasName;
  };
})(window);