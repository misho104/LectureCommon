'use strict'

const courseInputCell = "L5";
const ownerCell = "L9";
const errorCell = "L10";
const classMasterStart = "A2";
const studentMasterStart = "G2";
const studentStart = "O2";

/********************************************************************************
 *  エラーメッセージを表示
 */
function showError(sheet, message) {
  console.log(message);
  sheet.getRange(errorCell).setValue(message);
}

/********************************************************************************
 *  実行アカウントの情報を取得して ownerCell に登録
 */
function getOwnerID() {
  const sheet = SpreadsheetApp.getActiveSheet();
  var actUser = Session.getActiveUser();
  var email = actUser.getEmail();
  sheet.getRange(ownerCell).setValue(email);
  return email;
}

/********************************************************************************
 *  指定されたアカウントが所有する classroom の一覧を取得する
 */
function getOwnerCourses() {
  const sheet = SpreadsheetApp.getActiveSheet();
  showError(sheet, "");
  var start = sheet.getRange(classMasterStart);
  var startRow = start.getRow();
  var startColumn = start.getColumn();

  /*** (0) 処理対象となるアカウントを取得する ***/
  const owner = getOwnerID();
  console.log("Target ID: " + owner);

  // メールアドレスからアカウントの識別子を取得する
  var profileArgs = { userId: owner };
  try {
    var user = Classroom.UserProfiles.get(owner);
  }
  catch (e) {
    showError(sheet, "Teacher account unspecified");
    return;
  }
  console.log("ownerId: " + user.id);

  /*** (1) 指定されたアカウントの参加クラスを確認する ***/
  var optionalArgs = { teacherId: owner };
  var response = Classroom.Courses.list(optionalArgs);
  var result = response.courses;
  if (!(result && result.length > 0)) {
    showError(sheet, 'Fetching courses failed.')
    console.log('%s', result)
    return;
  }
  console.log('Classroom (%s)', result.length);
  for (let i = 0; i < result.length; i++) {
    console.log('%s (%s)', result[i].name, result[i].id);
  }
  if (!(sheet.getRange(startRow, startColumn, result.length + 1, 5 + 1).isBlank())) {
    showError(sheet, "Clear the target field before execute.");
    return;
  }
  for (let i = 0; i < result.length; i++) {
    sheet.getRange(startRow + i, startColumn + 0).setValue(result[i].id);
    sheet.getRange(startRow + i, startColumn + 1).setValue(result[i].name);
    sheet.getRange(startRow + i, startColumn + 2).setValue(result[i].ownerId == user.id ? "owner" : "non-owner");
    sheet.getRange(startRow + i, startColumn + 3).setValue(result[i].courseState);
    sheet.getRange(startRow + i, startColumn + 4).setValue(result[i].updateTime);
  }
}

/********************************************************************************
 *  courseInputCell に指定されたコースの学生を表示
 */
function getStudents() {
  const sheet = SpreadsheetApp.getActiveSheet();
  showError(sheet, "");
  var start = sheet.getRange(studentMasterStart);
  var startRow = start.getRow();
  var startColumn = start.getColumn();

  var courseId = sheet.getRange(courseInputCell).getValue();
  console.log("Course ID: " + courseId);

  var students = [];
  var token = "";
  while (true) {
    var result = Classroom.Courses.Students.list(courseId, { pageToken: token });
    if (!(result["students"] && result["students"].length > 0)) {
      showError(sheet, 'Fetching students failed.')
      console.log('%s', result)
      return;
    }
    students = students.concat(result["students"]);
    if (result["nextPageToken"]) {
      token = result["nextPageToken"];
    } else {
      break;
    }
  }
  var log_message = "";
  for (let i = 0; i < students.length; i++) {
    log_message += Utilities.formatString('%d %s %s\n', i, students[i].profile.name.fullName, students[i].userId);
  }
  console.log('Students (%s)\n%s', students.length, log_message);

  sheet.getRange(startRow, startColumn, students.length + 5, 4 + 1).clearContent()
  students.reverse();
  //students.sort(function (a, b) { return a.userId - b.userId; });

  for (let i = 0; i < students.length; i++) {
    sheet.getRange(startRow + i, startColumn + 0).setValue(students[i].courseId);
    sheet.getRange(startRow + i, startColumn + 1).setValue(students[i].userId);
    sheet.getRange(startRow + i, startColumn + 2).setValue(students[i].profile.name.fullName);
    sheet.getRange(startRow + i, startColumn + 3).setValue(students[i].profile.emailAddress);
  }
}

/********************************************************************************
 *  StudentMaster からの情報を StudentList に追加
 */
function copyStudentsFromMaster() {
  const sheet = SpreadsheetApp.getActiveSheet();
  var studentStartCell = sheet.getRange(studentStart);
  var studentStartRow = studentStartCell.getRow();
  var studentStartColumn = studentStartCell.getColumn();

  var message = "";
  var now = Utilities.formatDate(new Date(), "GMT+8", "yyyy-MM-dd HH:mm:ss");

  var students = [];
  for (let i = studentStartRow; true; i++) {
    var range = sheet.getRange(i, studentStartColumn, 1, 7)
    if (range.isBlank()) break;
    var data = range.getValues();
    students.push({
      email: data[0][0],
      googleName: data[0][1],
      studentName: data[0][2],
      studentId: data[0][3],
      googleId: data[0][4],
      githubId: data[0][5],
      lastUpdated: data[0][6],
      found: false,
      updated: false,
    });
  }
  console.log('original data: %s rows', students.length);
  message += "original " + students.length + " students\n";

  var masterStartCell = sheet.getRange(studentMasterStart);
  var masterStartRow = masterStartCell.getRow();
  var masterStartColumn = masterStartCell.getColumn();

  var i = masterStartRow;
  for (; true; i++) {
    var range = sheet.getRange(i, masterStartColumn, 1, 4)
    if (range.isBlank()) break;
    var data = range.getValues();
    var googleId = data[0][1];
    var googleName = data[0][2];
    var email = data[0][3];

    var found = false;
    students.forEach(s => {
      if (!found && s.email == email) {
        if (s.googleName != googleName || s.googleId != googleId) {
          s.updated = true;
        }
        s.googleName = googleName;
        s.googleId = googleId;
        s.lastUpdated = now;
        s.found = true;
        found = true;
      }
    });
    if (!found) {
      students.push({
        email: email,
        googleName: googleName,
        studentName: "(?)",
        studentId: "B?????????",
        googleId: googleId,
        githubId: "(?)",
        lastUpdated: now,
        found: true,
        updated: true,
      });
    }
  }
  console.log('master: %s rows', (i - masterStartRow));
  message += "master " + (i - masterStartRow) + " students\n";

  students.sort(function (a, b) {
    if (a.found == b.found) {
      return a.studentId.localeCompare(b.studentId);
    } else {
      return a.found - b.found;
    }
  });

  // Display students first
  var row = studentStartRow;
  students.forEach(s => {
    var message = (s.updated ? "[!]" : "") + s.lastUpdated;
    if (!s.found) message = "!!! Record Not Found";

    sheet.getRange(row, studentStartColumn, 1, 7).setValues([[
      s.email,
      s.googleName,
      s.studentName,
      s.studentId,
      s.googleId,
      s.githubId,
      message
    ]]);
    row++;
  });

  console.log('parsed: %s rows', (row - studentStartRow));
  message += "found " + (row - studentStartRow) + " students\n";

  showError(sheet, message)
}



// value index (zero origin)
const startRow = 1;
const courseIdColumn = 0;
const googleIdColumn = 1;
const messageColumn = 7;
const logColumn = 4;
const messageIdColumn = 5;

/********************************************************************************
 *  指定されたクラスで、個別の生徒宛に投稿を作成する
 */

function announcementsIndividualStudents() {
  const sheet = SpreadsheetApp.getActiveSheet();
  SpreadsheetApp.flush();
  var dataRange = sheet.getDataRange();
  var table = dataRange.getValues();
  var lastRow = dataRange.getLastRow()

  for (var row = startRow; row < lastRow; row++) {
    const command = String(table[row][logColumn]);
    if (command == "") {
      createAnnouncement(sheet, table, row);
    } else if (command == "delete") {
      deleteAnnouncement(sheet, table, row);
    }
  }
}

function createAnnouncement(sheet, table, row) {
  const courseId = String(table[row][courseIdColumn]);
  const googleId = String(table[row][googleIdColumn]);
  if (courseId == "" || googleId == "") {
    return;
  }
  var message = table[row].slice(messageColumn).join("\n");
  var data = {
    "courseId": courseId,
    "text": message,
    "assigneeMode": "INDIVIDUAL_STUDENTS",
    "individualStudentsOptions": {
      "studentIds": [googleId]
    },
    "state": "PUBLISHED",
  };

  //リンクの追加
  //if (linkURL != "") {
  //  data.materials = [{
  //    "link": {
  //       "url": linkURL,
  //       "title": "リンク",
  //       "thumbnailUrl": ""
  //    }
  //  }];
  // }

  try {
    //投稿内容の生成
    const response = Classroom.Courses.Announcements.create(data, courseId);
    sheet.getRange(row + 1, logColumn + 1).setValue("OK: Created.");
    sheet.getRange(row + 1, messageIdColumn + 1).setValue(response.id);
    sheet.getRange(row + 1, messageIdColumn + 1).setFontColor("#000000");
  }
  catch (e) {
    Logger.log(e);
    sheet.getRange(row + 1, logColumn + 1).setValue(e.message);
  }
}

function deleteAnnouncement(sheet, table, row) {
  const courseId = String(table[row][courseIdColumn]);
  const messageId = String(table[row][messageIdColumn]);
  try {
    Classroom.Courses.Announcements.remove(courseId, messageId);
    sheet.getRange(row + 1, logColumn + 1).setValue("OK: deleted.");
    sheet.getRange(row + 1, messageIdColumn + 1).setFontColor("#cccccc");
  }
  catch (e) {
    Logger.log(e);
    sheet.getRange(row + 1, logColumn + 1).setValue(e.message);
  }
}


/********************************************************************************
 *  Delete all the messages submitted from this system
 */
function deleteAllAnnouncements() {
  const sheet = SpreadsheetApp.getActiveSheet();
  var dataRange = sheet.getDataRange();
  var table = dataRange.getValues();
  var lastColumn = dataRange.getLastColumn()
  var lastRow = dataRange.getLastRow()

  var done = {};

  for (var row = startRow; row < lastRow; row++) {
    const courseId = String(table[row][courseIdColumn]);

    if (courseId == "" || !(done[courseId] === undefined)) continue;

    done[courseId] = 1;

    let res = Classroom.Courses.Announcements.list(courseId).announcements;
    if (!(res && res.length > 0)) {
      SpreadsheetApp.getActive().toast("No message found for " + courseId);
      continue;
    }
    var choice = SpreadsheetApp.getUi().alert("Clear all " + String(res.length) + " announcements for " + courseId, SpreadsheetApp.getUi().ButtonSet.OK_CANCEL);
    if (!(choice === SpreadsheetApp.getUi().Button.OK)) {
      continue;
    }

    let teacherId = Classroom.Courses.Teachers.get(courseId, Session.getActiveUser().getEmail());
    const userId = teacherId.userId;
    console.log(teacherId);

    let iCount = 0;
    console.log(res.length);
    for (let j = 0; j < res.length; j++) {
      console.log(res[j]);
      if (
        (res[j].assigneeMode == "INDIVIDUAL_STUDENTS") &&
        (res[j].creatorUserId == userId)) {
        try {
          Classroom.Courses.Announcements.remove(courseId, String(res[j].id));
          iCount++;
        }
        catch (e) {
          Logger.log(e);
          sheet.getRange(1 + row, logColumn + 1).setValue(e.message);
        }
      }
    }
    SpreadsheetApp.getActive().toast(iCount + " removed");
  }
}

// value index (zero origin)
const listCells = {
  "courseInput": "A1",
  "startCell": "A2",
  "courseId": 0,
  "googleId": 1,
  "studentId": 2,
  "studentName": 3,
  "updatedAt": 4,
  "messageId": 5,
  "message": 6,
}

function listAnnouncements() {
  const sheet = SpreadsheetApp.getActiveSheet();
  var courseId = String(sheet.getRange(listCells.courseInput).getValue());
  console.log("Course ID: " + courseId);

  let res = Classroom.Courses.Announcements.list(courseId).announcements.reverse();
  if (!(res && res.length > 0)) {
    SpreadsheetApp.getActive().toast("No message found for " + courseId);
    return;
  }
  let teacherId = Classroom.Courses.Teachers.get(courseId, Session.getActiveUser().getEmail());
  const userId = teacherId.userId;

  const origin = sheet.getRange(listCells.startCell);
  const startColumn = origin.getColumn();
  const startRow = origin.getRow();
  const lastRow = sheet.getDataRange().getLastRow();
  const lastColumn = sheet.getDataRange().getLastColumn();
  sheet.getRange(startRow, startColumn, lastRow - startRow + 1, lastColumn - startColumn + 1).clearContent();

  var row = -1;
  for (let i = 0; i < res.length; i++) {
    console.log(res[i]);
    if (
      (res[i].assigneeMode == "INDIVIDUAL_STUDENTS") &&
      (res[i].creatorUserId == userId)) {
      row++;
      var updated = Utilities.formatDate(new Date(res[i].updateTime), "GMT+8", "yyyy/MM/dd HH:mm:ss");
      var gidCell = origin.offset(row, listCells.googleId).getA1Notation();
      origin.offset(row, listCells.courseId).setValue(res[i].courseId);
      origin.offset(row, listCells.messageId).setValue(res[i].id);
      origin.offset(row, listCells.googleId).setValue(res[i].individualStudentsOptions.studentIds);
      origin.offset(row, listCells.studentId).setValue('=XLOOKUP($' + gidCell + ',Master!$S$2:$S$100,Master!$R$2:$R$100,"")');
      origin.offset(row, listCells.studentName).setValue('=XLOOKUP($' + gidCell + ',Master!$S$2:$S$100,Master!$Q$2:$Q$100,"")');
      origin.offset(row, listCells.updatedAt).setValue(updated);
      var messageLines = res[i].text.trim().split("\n");
      for (let j = 0; j < messageLines.length; j++)
        origin.offset(row, listCells.message + j).setValue(messageLines[j]);
    }
  }
}
