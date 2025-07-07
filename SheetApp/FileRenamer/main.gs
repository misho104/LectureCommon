// input 
const fileIdCellName = "F2";
// output
const dirNameCellName = "G2";
const fileNameCellName = "H2";
const now = Utilities.formatDate(new Date(), "GMT+8", "yyyy-MM-dd HH:mm:ss");


function getFilenames() {
  const sheet = SpreadsheetApp.getActiveSheet();
  var lastRow = sheet.getDataRange().getLastRow();

  var fileIdCell = sheet.getRange(fileIdCellName);
  var fileIdStartRow = fileIdCell.getRow();
  var fileIdColumn = fileIdCell.getColumn();

  var dirNameColumn = sheet.getRange(dirNameCellName).getColumn();
  var fileNameColumn = sheet.getRange(fileNameCellName).getColumn();

  for (let row = fileIdStartRow; row <= lastRow; row++) {
    var fileId = sheet.getRange(row, fileIdColumn, 1, 1).getValue();
    if (typeof fileId !== 'string' || fileId.length < 5) continue;
    console.log(fileId);

    console.log(fileId);
    try {
      var file = DriveApp.getFileById(fileId);
    } catch (e) {
      console.log(e.message);
      sheet.getRange(row, fileNameColumn, 1, 1).setValue(e.message);
      continue;
    }
    var fileName = file.getName();
    console.log(fileName);
    sheet.getRange(row, fileNameColumn, 1, 1).setValue(fileName);
    var dir = file.getParents();
    var dirName = dir.hasNext() ? dir.next().getName() : "(unknown dir)";
    sheet.getRange(row, dirNameColumn, 1, 1).setValue(dirName);
  }
}

const actionCellName = "J2";

function execute() {
  const sheet = SpreadsheetApp.getActiveSheet();
  var lastRow = sheet.getDataRange().getLastRow();

  var fileIdCell = sheet.getRange(fileIdCellName);
  var fileIdStartRow = fileIdCell.getRow();
  var fileIdColumn = fileIdCell.getColumn();

  var actionColumn = sheet.getRange(actionCellName).getColumn();

  for (let row = fileIdStartRow; row <= lastRow; row++) {
    var fileId = sheet.getRange(row, fileIdColumn, 1, 1).getValue();
    if (typeof fileId !== 'string' || fileId.length < 5) continue;

    var action = sheet.getRange(row, actionColumn, 1, 1).getValue();
    if (action == "rename") {
      var file = DriveApp.getFileById(fileId);
      //      var args = sheet.getRange(row, actionColumn +1, 1, 1).getValues()[0];
      var newName = sheet.getRange(row, actionColumn + 1, 1, 1).getValues()[0][0];
      console.log(row, action, file.getName(), newName);
      file.setName(newName);
      response = action + "/" + now + " : success!";
      sheet.getRange(row, actionColumn, 1, 1).setValue(response);
    }
  }
}

const courseIdCellName = "B1";
const courseWorksStartCellName = "A2";
const courseWorkIdCellName = "D1";
const submissionsStartCellName = "C2";

function listCourseWorks() {
  const sheet = SpreadsheetApp.getActiveSheet();
  try {
    var courseId = sheet.getRange(courseIdCellName).getValue();
    var courseWorksStartCell = sheet.getRange(courseWorksStartCellName);
    const response = Classroom.Courses.CourseWork.list(courseId, { pageSize: 50 });
    const courseWork = response.courseWork;
    if (!courseWork || courseWork.length === 0) {
      courseWorksStartCell.setValue("No coursework found.");
    } else {
      var courseWorksStartCellRow = courseWorksStartCell.getRow();
      var courseWorksStartCellColumn = courseWorksStartCell.getColumn();
      for (let i = 0; i < courseWork.length; i++) {
        const work = courseWork[i];
        sheet.getRange(courseWorksStartCellRow + i, courseWorksStartCellColumn, 1, 2).setValues([[work.id, work.title]])
        Logger.log(`課題名: ${work.title}}`);
      }
    }
  } catch (e) {
    Logger.log('エラー: ' + e.toString());
  }
}

function listSubmissions() {
  const sheet = SpreadsheetApp.getActiveSheet();
  try {
    var courseId = sheet.getRange(courseIdCellName).getValue();
    var courseWorkId = sheet.getRange(courseWorkIdCellName).getValue();
    var submissionsStartCell = sheet.getRange(submissionsStartCellName);
    const response =  Classroom.Courses.CourseWork.StudentSubmissions.list(courseId, courseWorkId, { pageSize: 50 });
    const submissions = response.studentSubmissions;
    if (!submissions || submissions.length === 0) {
      submissionsStartCell.setValue("No coursework found.");
    } else {
      var submissionsStartCellRow = submissionsStartCell.getRow();
      var submissionsStartCellColumn = submissionsStartCell.getColumn();
      for (let i = 0; i < submissions.length; i++) {
        const sub = submissions[i];
        const attachments = sub.assignmentSubmission.attachments;
        const nFiles = attachments ? attachments.length : 0;
        sheet.getRange(submissionsStartCellRow + i, submissionsStartCellColumn, 1, 3).setValues([[sub.userId, sub.updateTime, nFiles]])
        if(nFiles > 0){
          var columns = attachments.map(i => [i.driveFile.id, i.driveFile.title]).flat();
          Logger.log(columns.length);
          Logger.log(columns);
          sheet.getRange(submissionsStartCellRow + i, submissionsStartCellColumn + 3, 1, columns.length).setValues([columns]);
        }
      }
    }
  } catch (e) {
    Logger.log('エラー: ' + e.toString());
  }
}
