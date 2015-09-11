'use strict';

angular.module('schedule.day', [
		'ngAnimate',
		'schedule.data'
	])

/**
 * Lays out the schedule for an individual day
 **/
.controller('DayCtrl', [
		'$scope', 'user', 'shared', 'Student', 'Lesson',
function($scope,   user,   shared,   Student,   Lesson) {

	function parseDate(day, hour) {
		day = day.split('-');
		hour = hour.split(':');
		return new Date(+day[0], +day[1]-1, +day[2], +hour[0], +hour[1]);
	}

	function generateTable(day) {
		var slots = ((day || {}).data || {}).slots || [], r = -1,
			cols = [], map = {}, rows = [],
			userId = user.id, date = (day || {}).date || new Date(),
			limit = +new Date(),
			deleteLimit = +new Date() + (24 * 60 * 60 * 1000);
		$scope.table = { cols:cols, rows:rows };
		slots.forEach(function(slot) {
			var id = (slot.teacher || {}).id;
			if (!(id in map)) {
				cols[(map[id] = cols.length)] = slot.teacher;
			}
			if (!rows[r] || slot.start !== rows[r].start) {
				var time = slot.start.split(':')
				rows[++r] = {
					label:((+time[0] % 12) || 12) +
						':' + time[1] +
						((+time[0] >= 12) ? 'pm' : 'am'),
					start:slot.start,
					end:slot.end,
					cells:[]
				};
			}
			rows[r].cells[map[id]] = slot;

			var baseAvail = slot.teacher &&
					(+parseDate(day.day, slot.start) > limit),
				canAdd = (!slot.student && (user.bought > user.used));
			slot.isMine = slot.student && (slot.student.user.id === userId);
			slot.isAvailable = baseAvail && !slot.student;
			slot.isChangable = (slot.teacher && !slot.teacher.deleted) &&
				(user.admin || (baseAvail && (slot.isMine || canAdd)));
			slot.isDeleteable = slot.isChangable &&
				(+parseDate(day.day, slot.start) > deleteLimit);
			slot.isBreak = slot.student && (slot.student.id === 1517);
		});
		rows.forEach(function(row) {
			for (var c = 0, cc = cols.length; c < cc; ++c) {
				row.cells[c] = row.cells[c] || {};
			}
		});
		if (!shared.students.length && user.id) {
			shared.students = Student.query({ user:user.id });
		}
		$scope.user = user;
		$scope.students = shared.students;
		$scope.title = shared.dayNames[date.getDay()] + ', ' +
			shared.monthNames[date.getMonth()] + ' ' +
			date.getDate() + shared.ordinal(date.getDate()) + ' ' +
			date.getFullYear();
	}
	function revert() {
		location.reload(true); // exception, unknown state so reload
	}

	generateTable($scope.day = shared.selected);
	$scope.$on('selectedChange', function(evt, selected) {
		generateTable($scope.day = selected);
    });

	$scope.lessonChange = function(slot) {
		var date = slot.day + ' ' + slot.start, lesson,
			params = { date:date, teacher:slot.teacher.id, id:slot.id },
			wasMine = slot.isMine;
		slot.isMine = slot.student && (slot.student.user.id === user.id);
		slot.isAvailable = !slot.student;
		if (!slot.student && !slot.id) {
			// Do nothing, because there wasn't a student there before
		} else if (!slot.student) {
			delete slot.id;
			if (wasMine) {
				--user.used;
				if (user.used + 1 === user.bought) { generateTable($scope.day); }
			}
			Lesson.remove(params, null, null, revert);
		} else if (slot.id) {
			Lesson.update(params, slot, null, revert);
		} else {
			if (slot.isMine) {
				++user.used;
				if (user.used === user.bought) { generateTable($scope.day); }
			}
			Lesson.create(params, slot, function(lesson) {
				slot.id = lesson.id;
			}, revert);
		}
		$scope.$parent.$broadcast('lessonChange', $scope.day, slot);
	};

} ]);

