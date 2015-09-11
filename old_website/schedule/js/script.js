(function(win, doc){
'use strict';

/**
 * Helpers
 **/
var transform = (('transform' in doc.body.style) && 'transform') ||
		(('webkitTransform' in doc.body.style) && 'webkitTransform') ||
		'transform';
function trim(str) {
	return str.replace(/^\s+/, '').replace(/\s+$/, '');
}

function addClass(el, cls) {
	var className = ' ' + el.className + ' ';
	if (!~className.indexOf(' ' + cls + ' ')) {
		el.className = trim(className + cls);
	}
}
function hasClass(el, cls) {
	var className = ' ' + el.className + ' ', c;
	return !!~className.indexOf(' ' + cls + ' ');
}
function removeClass(el, cls) {
	var className = ' ' + el.className + ' ', c;
	if (~className.indexOf(' ' + cls + ' ')) {
		el.className = trim(className.replace(' ' + cls + ' ', ' '));
	}
}

function randomTransform() {
	var minScale = 1.2, maxScale = 1.5,
		minTrans = 5, maxTrans = 10,
		scale = Math.random() * (maxScale - minScale) + minScale,
		transX = (Math.random() * (maxTrans - minTrans) + minTrans)
			* (Math.random < .5 ? -1 : 1),
		transY = (Math.random() * (maxTrans - minTrans) + minTrans)
			* (Math.random < .5 ? -1 : 1);
	return 'scale(' + scale.toFixed(2) + ') translate(' + transX.toFixed(2) + '%,' + transY.toFixed(2) + '%)';
}

var on = doc.addEventListener ?
		function(el, evt, fn) { el.addEventListener(evt, fn, false); } :
		function(el, evt, fn) { el.attachEvent('on'+evt, fn); },
	off = doc.removeEventListener ?
		function(el, evt, fn) { el.removeEventListener(evt, fn, false); } :
		function(el, evt, fn) { el.detachEvent('on'+evt, fn); },
	preventDefault = function(evt) {
			return evt.preventDefault ? evt.preventDefault() : (evt.returnValue = false);
		};



/**
 * Get Current User
 **/
(function() {

win.user = win.user || { loading:true };

var req = new XMLHttpRequest();
req.onreadystatechange = function () {
    if (4 !== req.readyState) { return; }
	win.user.loading = false;
	try {
		var user = JSON.parse(req.responseText), u;
		for (u in user) { win.user[u] = user[u]; } // copy to, don't replace the object
	} catch(err) {}

	if (!win.user.id) {
		addClass(doc.querySelector('.header-signin'), 'is-shown');
		return;
	}

	var username = doc.querySelector('.header-user');
	username.textContent = user.name;
	addClass(username, 'is-shown');
	addClass(doc.querySelector('.header-phone'), 'is-signedin');
	if (!win.user.admin) {
		doc.querySelector('.legacyadmin').style.display = 'none';
		doc.querySelector('.admin').style.display = 'none';
	}

	on(username, 'click', menuToggle);
};
req.open('GET', 'user.json', true);
req.send();

function menuToggle(evt) {
	if ('touchend' === evt.type) { // don't listen to click if using touch
		off(doc.querySelector('.header-user'), 'click', menuToggle);
	}
	off(doc, 'click', menuToggle);

	var menu = doc.querySelector('.menu-user'),
		isOpen = hasClass(menu, 'is-open');
	if (isOpen) {
		removeClass(menu, 'is-open');
	} else {
		menu.style.display = 'block';
	}
	setTimeout(function() {
		if (isOpen) {
			menu.style.display = 'none';
		} else {
			addClass(menu, 'is-open');
			on(doc, 'click', menuToggle);
		}
	}, isOpen ? 500 : 16);
}

}());



/**
 * Navigation (small screens only)
 **/
(function(){

function Navigation(el) {
	var navigation = {
		el:el, touch:false, opening:false, timer:null,
		onclick: function(evt) { click(navigation, evt || win.event); }
	};

	on(el, 'click', navigation.onclick);
	on(el, 'touchend', navigation.onclick);

	return navigation;
}
var NavigationP = Navigation.prototype;

function click(navigation, evt) {
	if ('touchend' === evt.type) { navigation.touch = true; }
	if (navigation.opening) { return preventDefault(evt); }
	if (navigation.touch && 'click' === evt.type) { return; }

	if (/\bis-selected\b/.test(evt.target.className) && !/\bis-open\b/.test(navigation.el.className)) {
		addClass(navigation.el, 'is-open');
		navigation.opening = true;
	} else {
		removeClass(navigation.el, 'is-open');
	}

	clearTimeout(navigation.timer);
	navigation.timer = setTimeout(function() {
		navigation.opening = false;
		navigation.timer = null;
	}, 400);
}

setTimeout(function() { Navigation(doc.querySelector('.navigation')); }, 200);

}());



/**
 * Gallery
 **/
(function(){

function Gallery(el) {
	var gallery = { el:el, images:[], timer:null },
		images = el.querySelectorAll('.gallery-image, .gallery-text'),
		i, ii = images.length,
		pages = doc.createElement('div'), page,
		prevEl = doc.createElement('a'),
		nextEl = doc.createElement('a');
	pages.className = 'gallery-pages';
	gallery.pages = [];
	gallery.pages.el = pages;
	for (i = 0; i < ii; ++i) {
		gallery.images[i] = GalleryImage(gallery, images[i], i);

		page = pages.appendChild(doc.createElement('a'));
		page.className = 'gallery-page';
		page.setAttribute('data-page', ''+i);
		gallery.pages[i] = page;
	}
	addClass(gallery.pages[gallery.selected], 'is-selected');
	el.appendChild(gallery.pages.el);

	prevEl.className = 'gallery-prev';
	nextEl.className = 'gallery-next';
	el.appendChild(prevEl);
	el.appendChild(nextEl);

	gallery.onclick = function(evt) { click(gallery, evt || win.event); };
	on(el, 'click', gallery.onclick);
	on(el, 'touchend', gallery.onclick);

	fadeIn(gallery, gallery.selected);
	startAnimation(gallery);
	addClass(el, 'is-ready');
	return gallery;
}

function GalleryImage(gallery, el, i) {
	var image = { el:el, index:i, img:null, loaded:false, timer:null };
	if (image.selected = /\bis-selected\b/.test(el.className)) {
		gallery.selected = i;
	}
	if (/\bgallery-text\b/.test(el.className)) {
		image.img = { style:{} };
	} else if (image.img = el.querySelector('.gallery-image-img')) {
		image.img.style[transform] = randomTransform();
		if (!(image.loaded = !!image.img.naturalWidth)) {
			image.onload = function() { image.loaded = true; };
		}
	}
	return image;
}

function startAnimation(gallery) {
	stopAnimation(gallery);
	gallery.timer = setTimeout(function() {
		// try to use rAF, so we pause while backgrounded
		if (!win.requestAnimationFrame) { return next(gallery); }
		win.requestAnimationFrame(function() { next(gallery); });
	}, 5000);
	preload(gallery, (gallery.selected + 1) % gallery.images.length);
}

function stopAnimation(gallery) {
	clearTimeout(gallery.timer);
	gallery.timer = null;
}

function next(gallery, index) {
	var ii = gallery.images.length, selected = gallery.selected;
	if (isNaN(index)) { index = selected + 1; }
	index = (index + ii) % ii;
	fadeOut(gallery, selected);
	fadeIn(gallery, gallery.selected = index);
	startAnimation(gallery);
}

function preload(gallery, index) {
	var image = gallery.images[index];
	if (!image.img) {
		image.img = new Image();
		image.img.onload = function() { image.loaded = true; };
		image.img.className = 'gallery-image-img';
		image.img.src = image.el.getAttribute('data-src');
		image.img.style[transform] = randomTransform();
		image.el.appendChild(image.img);
		image.el.removeAttribute('data-src');
	}
}

function fadeOut(gallery, index) {
	var image = gallery.images[index],
		page = gallery.pages[index];
	removeClass(page, 'is-selected');
	removeClass(image.el, 'is-open');
	clearTimeout(image.timer);
	image.timer = setTimeout(function() {
		removeClass(image.el, 'is-selected');
		image.timer = null;
	}, 1100);
}

function fadeIn(gallery, index) {
	preload(gallery, index);
	var image = gallery.images[index],
		page = gallery.pages[index];
	image.el.parentNode.appendChild(image.el); // move to last in document order
	clearTimeout(image.timer);
	image.timer = setTimeout(function() {
		addClass(page, 'is-selected');
		addClass(image.el, 'is-selected');
		image.img.style[transform] = randomTransform();
		image.timer = null;
	}, 16);
}

function click(gallery, evt) {
	if ('touchend' === evt.type) { // don't listen to click if using touch
		off(gallery.el, 'click', gallery.onclick);
	}
	var el = evt.target, cls = ' ' + el.className + ' ', page;
	if (~cls.indexOf(' ellipsis-show-full ')) {
		stopAnimation(gallery); // stop rotating while I'm reading a long testimonial
		addClass(el.parentNode.parentNode, 'is-open');
		return;
	}

	if (~cls.indexOf(' gallery-page ')) {
		page = +el.getAttribute('data-page');
	} else if (~cls.indexOf(' gallery-prev ')) {
		page = gallery.selected - 1;
	} else if (~cls.indexOf(' gallery-next ')) {
		page = gallery.selected + 1;
	} else { return; } // don't jump page
	next(gallery, page);
}

setTimeout(function() {
	var galleries = doc.querySelectorAll('.gallery'), g = galleries.length;
	while (g) { Gallery(galleries[--g]); }
}, 200);

}());



/**
 * Account page
 **/
(function(){

on(doc, 'click', click);
on(doc, 'touchend', click);

function click(evt) {
	if ('touchend' === evt.type) { // don't listen to click if using touch
		off(doc, 'click', click);
	}
	var details, el = evt.target, cls = ' ' + el.className + ' ', disabled;
	if (~cls.indexOf(' summary ')) {
		details = doc.querySelector(el.target);
		if (disabled = hasClass(el, 'is-open')) {
			removeClass(el, 'is-open');
			removeClass(details, 'is-open');
		} else {
			addClass(el, 'is-open');
			addClass(details, 'is-open');
		}
		var inputs = details.querySelectorAll('input'), i = inputs.length;
		while (--i >= 0) { inputs[i].disabled = disabled; }
	}

	if (~cls.indexOf(' add-student ')) {
		var row, studentRows = doc.querySelectorAll('.account-student'),
			index = studentRows.length - 1, // exclude template row
			lastStudent = studentRows[index], input;

		if (index < 10) { // only allow 10 students
			row = doc.querySelector('#new_student').cloneNode(true);
			row.id = null;
			removeClass(row, 'hidden');
			row.innerHTML = row.innerHTML.replace(/\{i\}/g, index);
			lastStudent.parentNode.insertBefore(row, lastStudent.nextSibling);
			input = row.querySelector('input');
			input.disabled = false;
			input.focus();
			if (9 === index) { el.parentNode.removeChild(el); }
		}
	}
}

}());


/**
 * EditItems page
 **/
(function(){

on(doc, 'click', click);
on(doc, 'touchend', click);

function click(evt) {
	if ('touchend' === evt.type) { // don't listen to click if using touch
		off(doc, 'click', click);
	}
	var details, cls = ' ' + evt.target.className + ' ';
	if (~cls.indexOf(' add-item ')) {
		var row, itemRows = doc.querySelectorAll('.account-item'),
			index = itemRows.length - 1, // exclude template row
			lastItem = itemRows[index], input;

		row = doc.querySelector('#new_item').cloneNode(true);
		row.id = null;
		removeClass(row, 'hidden');
		lastItem.parentNode.insertBefore(row, lastItem.nextSibling);
		input = row.querySelector('input');
		input.disabled = false;
		input.focus();
	}
	if (~cls.indexOf(' remove-item ')) {
		var row = evt.target;
		while ((row != null) && (!(row instanceof HTMLTableRowElement)))
			row = row.parentNode;
		row.parentNode.removeChild(row);
	}
}

}());

/**
 * EditTeachers page
 **/
(function(){

on(doc, 'click', click);
on(doc, 'touchend', click);

function click(evt) {
	if ('touchend' === evt.type) { // don't listen to click if using touch
		off(doc, 'click', click);
	}
	var details, cls = ' ' + evt.target.className + ' ';
	if (~cls.indexOf(' add-teacher ')) {
		var row, teacherRows = doc.querySelectorAll('.account-teacher'),
			index = teacherRows.length - 1, // exclude template row
			lastTeacher = teacherRows[index], input;

		row = doc.querySelector('#new_teacher').cloneNode(true);
		row.id = null;
		removeClass(row, 'hidden');
		lastTeacher.parentNode.insertBefore(row, lastTeacher.nextSibling);
		input = row.querySelector('input');
		input.disabled = false;
		input.focus();
	}
	if (~cls.indexOf(' remove-teacher ')) {
		var row = evt.target;
		while ((row != null) && (!(row instanceof HTMLTableRowElement)))
			row = row.parentNode;
		row.parentNode.removeChild(row);
	}
}

}());

})(this, document);

