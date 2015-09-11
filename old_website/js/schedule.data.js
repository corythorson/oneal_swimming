'use strict';

angular.module('schedule.data', [
		'ngResource'
	])

/**
 * Currently logged in user
 **/
.service('user', [
		'$window',
function($window) {
	return $window.user || ($window.user = { loading:true });
} ])

/**
 * Shared data (selected day)
 **/
.service('shared', [
		'$rootScope',
function($rootScope) {
	var today = new Date(), selected;
	today = new Date(today.getFullYear(), today.getMonth(), today.getDate());
	var shared = {
			today:today,
			students:[],
			data:{}, // cache of loaded schedule data
			monthNames:[
				'January', 'February', 'March',
				'April', 'May', 'June',
				'July', 'August', 'September',
				'October', 'November', 'December'
			],
			dayNames:[
				'Sunday', 'Monday', 'Tuesday',
				'Wednesday', 'Thursday', 'Friday',
				'Saturday'
			],
			ordinal: function(n) {
				if (11 !== n && (1 === n % 10)) { return 'st'; }
				if (12 !== n && (2 === n % 10)) { return 'nd'; }
				if (13 !== n && (3 === n % 10)) { return 'rd'; }
				return 'th';
			}
		};
	Object.defineProperty(shared, 'selected', {
		get:function() { return selected; },
		set:function(sel) {
			$rootScope.$broadcast('selectedChange', selected = sel);
		}
	});
	return shared;
} ])

/**
 * Get the students for a user (the one signed in)
 **/
.factory('Student', [
		'$resource',
function($resource) {
	return $resource(
		'students/:user.json',
		{ user:'all' },
		{}
	);
} ])

/**
 * Get the schedule for a whole month at a time
 **/
.factory('Month', [
		'$resource',
function($resource) {
	return $resource(
		'schedule/:location/:month.json',
		{ location:'af', month:'@month' },
		{}
	);
} ])

/**
 * Post / Put / Delete a particular lesson slot
 **/
.factory('Lesson', [
		'$resource',
function($resource) {
	return $resource(
		'schedule/:location/:date/:teacher/:id.json',
		{ location:'af', date:'@date', teacher:'@teacher', id:'@id' },
		{
			create:{ method:'POST' },
			update:{ method:'PUT' },
			remove:{ method:'DELETE' }
		}
	);
} ]);

