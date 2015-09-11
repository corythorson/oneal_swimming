'use strict';

angular.module('schedule.calendar', [
		'ngAnimate',
		'schedule.data'
	])

/**
 * Lays out a month's schedule
 **/
.controller('CalendarCtrl', [
		'$scope', 'user', 'shared', 'Month',
function($scope,   user,   shared,   Month) {

	var today = shared.today,
		data = shared.data,
		shown;

	function pad2(num) { return ('00' + num).slice(-2); }

	$scope.reverse = false;
	$scope.shared = shared;

	$scope.prev = function() {
		var year = shown[0], month = shown[1] - 1;
		if (month < 0) {
			--year;
			month = 11;
		}
		generateDays(year, month);
	};

	$scope.next = function() {
		var year = shown[0], month = shown[1] + 1;
		if (month >= 12) {
			++year;
			month = 0;
		}
		generateDays(year, month);
	};

	$scope.select = function(day) {
		if (day.isExpandable) {
			if (shared.selected) { shared.selected.isSelected = false; }
			if (shared.selected === day) {
				shared.selected = null;
			} else {
				shared.selected = day;
				day.isSelected = true;
			}
		}
	};

	$scope.$on('lessonChange', function(evt, day, slot) {
		day.isLesson = isLesson(day);
	});

	function generateDays(year, month) {
		shown = [ year, month ];

		var days = [], day = new Date(year, month, 1), d, key, nday;
		day.setDate(-day.getDay());
		do {
			for (d = 0; d < 7; ++d) {
				day.setDate(day.getDate() + 1);
				key = day.getFullYear() + '-' + pad2(day.getMonth() + 1);
				data[key] = data[key] || Month.get({ month:key }, updateMonthData);

				nday = {
					date:new Date(+day),
					day:key + '-' + pad2(day.getDate()),
					month:key,
					data:null,

					isSelected:shared.selected && shared.selected.date === +day,
					isToday:(+today === +day),
					isOtherMonth:(month !== day.getMonth()),
					isUnSchedulable:!(d % 6) || (+day <= +today),
					isExpandable:!!(d % 6),
					isLesson:false
				};
				if (nday.isSelected) { shared.selected = nday; }
				nday.isUnSchedulable = isUnSchedulable(nday);
				nday.isExpandable = isExpandable(nday);
				nday.isLesson = isLesson(nday);
				nday.data = getDayData(nday);
				days.push(nday);
			}
		} while (month === day.getMonth());
		$scope.title = [ shared.monthNames[month] + ' ' + year ];
		$scope.months = [ { month:year + '-' + pad2(month + 1), days:days } ];
	}

	function updateMonthData(month) {
		var userId = (user || {}).id;
		(month.days || []).forEach(function(day) {
			month[day.day] = day;
			day.isLesson = day.slots.some(function(slot) {
					return slot.student && (slot.student.user.id === userId);
				});
		});
		if (!$scope.months) { return; }
		$scope.months[0].days.forEach(function(day) {
			day.isUnSchedulable = isUnSchedulable(day);
			day.isExpandable = isExpandable(day);
			day.isLesson = isLesson(day);
			day.data = getDayData(day);
		});
		shared.selected = shared.selected;
	}

	function getDayData(day) {
		return (data[day.month] || {})[day.day];
	}

	function isLesson(day) {
		var userId = (user || {}).id,
			dData = getDayData(day);
		if (!dData || !dData.slots) { return false; }
		return dData.slots.some(function(slot) {
				return slot.student && (slot.student.user.id === userId);
			});
	}

	function isExpandable(day) {
		var dData = getDayData(day);
		if (!dData || !dData.slots) { return !!(day.date.getDay() % 6); }
		return !!dData.slots.length;
		
	}

	function isUnSchedulable(day) {
		if (+day.date <= +today) { return true; }
		var dData = getDayData(day);
		if (!dData || !dData.slots) { return !(day.date.getDay() % 6) || (+day.date <= +today); }
		return !dData.slots.filter(function(slot) {
				return slot.teacher && !slot.teacher.deleted;
			}).length;
	}

	generateDays(today.getFullYear(), today.getMonth());

} ]);

