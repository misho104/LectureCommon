/**
 * Check multiple-choice answers.
 * 
 * @param {string}   input    the answer
 * @param {string}   choice1  semicolon-separated strings for each of which point1 is given.
 * @param {number}   point1   the point given for choice 1. integer is better.
 * @param {string}   choice2  semicolon-separated strings for each of which point2 is given.
 * @param {number}   point2   the point given for choice 2. integer is better.
 * @customfunction
 */
function checkChoices(input, choice1, point1, choice2, point2){
  var point = 0;
  choice1.split(":").forEach(function(v){ if(input.includes(v)) { point += point1; } });
  choice2.split(":").forEach(function(v){ if(input.includes(v)) { point += point2; } });
  return point;
}
