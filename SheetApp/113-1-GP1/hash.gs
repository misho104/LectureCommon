function generateHash(input, secret){
  var inputDigits = input.toString().replace(/[^\d]/g, "", );
  var rawHash = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_1, inputDigits + secret);
  var letters = "ABEFGHKLMNPRTWXY";
  var textHash = inputDigits + "-";
  for (let j = 0; j < 3; j++) {
    textHash += letters[Math.abs(rawHash[j] % 16)];
  }
  return textHash;
}

function checkHash(input, secret){
  var inputDigits = input.toString().replace(/[^\d]/g, "");
  var inputAlph = input.toString().replace(/[^A-Za-z]/g, "").toUpperCase();
  return generateHash(inputDigits, secret) == inputDigits + "-" + inputAlph;
}
