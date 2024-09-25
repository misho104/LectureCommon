'use strict'

function getScriptSecret(key) {
  let secret = PropertiesService.getScriptProperties().getProperty(key);
  if (!secret) throw Error(`Secret ${key} is empty`);
  return secret;
}

var folderID = getScriptSecret("UPLOAD_FOLDER"); // set Script Property
var masterSheet = SpreadsheetApp.getActive().getSheetByName("Master");


function doGet() {
  return HtmlService.createTemplateFromFile('index').evaluate();
}

function findStudentInfo(id) {
  //  const studentStart = "O2";
  var lastRow = masterSheet.getDataRange().getLastRow();
  var start = masterSheet.getRange(studentStart);
  var studentTable = masterSheet.getRange(start.getRow(), start.getColumn(), lastRow - 1, 4).getValues();
  for (let i = 0; i < studentTable.length; i++) {
    if (studentTable[i][3] == id) {
      return { "email": studentTable[i][0], "name": studentTable[i][2] };
    }
  }
  return { "email": "", "name": "" };
}
function updateStudentInfo(studentID) {
  console.log(studentID);
  var name = findStudentInfo(studentID).name;
  return name ? name : "invalid ID";
}

function uploadFile(sid, fileName, base64data) {
  try {
    console.log(sid, fileName, base64data.length);
    const data = base64data.split(',');
    const mime = data[0].substring(5).split(";")[0];
    console.log(mime);

    const student = findStudentInfo(sid);
    if (student.email == "") {
      return "No student found.";
    }
    if (fileName == "" || data[1] == "") {
      return "Invalid data.";
    }
    const blob = Utilities.newBlob(Utilities.base64Decode(data[1]), mime, sid + fileName);

    var folder = DriveApp.getFolderById(folderID);
    var file = folder.createFile(blob);
    file.setDescription("Shared with " + sid);
    file.addEditor(student.email);
    var fileUrl = file.getUrl();
    if(fileUrl.substring(0, 4) != "http"){
      return "invalid URL: " + fileUrl;
    }
    return fileUrl;
  } catch (error) {
    return error.toString();
  }
}