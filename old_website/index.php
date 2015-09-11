<?php

date_default_timezone_set('America/Denver');

$basedir = $_SERVER['DOCUMENT_ROOT'];

require_once $basedir.'/../vendor/autoload.php';
require_once $basedir.'/../lib/autoload.php';

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

$app = new Silex\Application();

// environment
if (isset($_SERVER['ENVIRONMENT'])) {
	$app['environment'] = $_SERVER['ENVIRONMENT'];
	$app['debug'] = true;
} else {
	$app['environment'] = 'production';
	$app['debug'] = false;
}

// session
$app->register(new Silex\Provider\SessionServiceProvider(), array(
	'session.storage.options' => array(
		'name'            => 's', // cookie name
		'cookie_httponly' => true,
		'cookie_secure'   => false,
	)
));

// parse JSON request body
$app->before(function (Request $request) {
	if (0 === strpos($request->headers->get('Content-Type'), 'application/json')) {
		$data = json_decode($request->getContent(), true);
		$request->request->replace(is_array($data) ? $data : array());
	}
});

// generate pages from templates
$render = function($page, $opts=array()) use ($app, $basedir) {
	// load strings from json configs TODO: from database
	$base = file_get_contents($basedir.'/../lib/template/base.json');
	$base = json_decode($base, true);
	$json = file_get_contents($basedir.'/../lib/template/'.$page.'.json');
	$json = array_merge($base, json_decode($json, true));
	extract($json); // bring variables into scope
	$user = $app['session']->get('user');

	$editmode = isset($opts['editmode']);
	if (isset($opts['variables'])) {
		extract($opts['variables']);
	}

	// run template
	ob_start(); // dont print anything
	require $basedir.'/../lib/template/base.html.php';
	$html = ob_get_contents();
	ob_end_clean(); // clear buffer, end buffering

	$response = new Response($html, 200);
	$nocache = in_array($page, array( 'schedule', 'signup', 'signin', 'account', 'edititems', 'editteachers', 'purchase', 'terms' ));
	if (!$editmode && !$nocache) {
		$response->setPublic();
		$response->setMaxAge(60 * 60 * 24 * 1); // 1 day
	}
	return $response;
};


/**
 * Routes
 **/

// main pages
$app->get('/', function() use ($app) {
    return $app->redirect('/signin.html');
});
$app->get('/teachers.html', function() use ($app) {
    return $app->redirect('/signin.html');
});
$app->get('/lessons.html', function() use ($app) {
    return $app->redirect('/signin.html');
});
$app->get('/location.html', function() use ($app) {
    return $app->redirect('/signin.html');
});
/*
$app->get('/', function() use ($render) { return $render('index'); });
$app->get('/teachers.html', function() use ($render) { return $render('teachers'); });
$app->get('/lessons.html', function() use ($render) { return $render('lessons'); });
$app->get('/location.html', function() use ($render) { return $render('location'); });
*/
$app->get('/policies.html', function() use ($render) { return $render('policies'); });
$user = $app['session']->get('user');
if (!!$user['Admin'])
{
	$app->get('/admin.html', function() use ($render) { return $render('admin'); });
	$app->get('/changeuser.html', function()
		use ($app, $render)
		{
			if (isset($_GET['UserID']))
			{
				$user = $app['session']->get('user');
				$newuser = Controller\Account::signInById($_GET['UserID']);
				$app['session']->set('user', $newuser);
				$app['session']->set('olduser', $user);
				return $app->redirect('schedule.html', 303);
			}
			return $render('changeuser'); 
		}
	);
	$app->get('/edititems.html', function() use ($app, $render) {
		$user = $app['session']->get('user');
		$opts = array();
		$opts['variables'] = Controller\Admin::getItems();
		$opts['variables']['error'] = $app['session']->getFlashBag()->get('error')[0];
		return $render('edititems', $opts);
	});
	$app->post('/edititems', function() use ($app) {
		$error = Controller\Admin::updateItems($app['request']->request->all());
		$app['session']->getFlashBag()->add('error', $error);
		return $app->redirect('edititems.html', 303);
	});
	$app->get('/editteachers.html', function() use ($app, $render) {
		$user = $app['session']->get('user');
		$opts = array();
		$opts['variables'] = Controller\Admin::getTeachers();
		$opts['variables']['error'] = $app['session']->getFlashBag()->get('error')[0];
		return $render('editteachers', $opts);
	});
	$app->post('/editteachers', function() use ($app) {
		$error = Controller\Admin::updateTeachers($app['request']->request->all());
		$app['session']->getFlashBag()->add('error', $error);
		return $app->redirect('editteachers.html', 303);
	});
	$app->get('/addteacherhours.html', function() use ($app, $render) {
		$user = $app['session']->get('user');
		$opts = array();
		$opts['variables'] = Controller\Admin::getTeachers();
		$opts['variables']['error'] = $app['session']->getFlashBag()->get('error')[0];
		$opts['variables']['form'] = $app['session']->getFlashBag()->get('form')[0];
		return $render('addteacherhours', $opts);
	});
	$app->post('/addteacherhours', function() use ($app) {
		$form = $app['request']->request->all();
		$error = Controller\Admin::addTeacherHours($form);
		$app['session']->getFlashBag()->add('error', $error);
		$app['session']->getFlashBag()->add('form', $form);
		return $app->redirect('addteacherhours.html', 303);
	});
	$app->get('/removeteacherhours.html', function() use ($app, $render) {
		$user = $app['session']->get('user');
		$opts = array();
		$opts['variables'] = Controller\Admin::getTeachers();
		$opts['variables']['error'] = $app['session']->getFlashBag()->get('error')[0];
		return $render('removeteacherhours', $opts);
	});
	$app->post('/removeteacherhours', function() use ($app) {
		$error = Controller\Admin::removeTeacherHours($app['request']->request->all());
		$app['session']->getFlashBag()->add('error', $error);
		return $app->redirect('removeteacherhours.html', 303);
	});
	$app->get('/userbalance.html', function() use ($app, $render) {
		$user = $app['session']->get('user');
		$opts = array();
		$opts['variables']['balances'] = DB::getUserBalances();
		$opts['variables']['error'] = $app['session']->getFlashBag()->get('error')[0];
		return $render('userbalance', $opts);
	});
}

// account management
$app->get('/signup.html', function() use ($app, $render) {
	$user = $app['session']->get('user');
	if (!empty($user)) { $app['session']->invalidate(); } // logout first
	$opts = array();
	$opts['variables'] = array();
	$opts['variables']['form'] = $app['session']->getFlashBag()->get('form')[0];
	$opts['variables']['messages'] = $app['session']->getFlashBag()->get('messages')[0];
	return $render('signup', $opts);
});
$app->post('/signup', function() use ($app) {
	$messages = Controller\Account::signup(array( 'app'=>$app ), $app['request']->request->all());
	if ($app['session']->get('user')) {
		return $app->redirect('schedule.html', 303);
	}
	$app['session']->getFlashBag()->add('form', $app['request']->request->all());
	$app['session']->getFlashBag()->add('messages', $messages);
	return $app->redirect('signup.html', 303);
});
$app->get('/signin.html', function() use ($app, $render) {
	$user = $app['session']->get('user');
	if (!empty($user)) { return $app->redirect('schedule.html'); }
	return $render('signin');
});
$app->post('/signin', function() use ($app) {
	$user = Controller\Account::signin($app['request']->request->all());
	if (!empty($user)) {
		$app['session']->set('user', $user);
		return $app->redirect('schedule.html', 303);
	} else {
		// TODO: errors
		return $app->redirect('signin.html', 303);
	}
});
$app->get('/signout', function() use ($app) {
	$user = $app['session']->get('olduser');
	if (isset($user))
	{
		$app['session']->set('olduser', null);
		$app['session']->set('user', $user);
		return $app->redirect('changeuser.html', 303);
	}
	$app['session']->invalidate();
	return $app->redirect('.', 303);
});
$app->get('/user.json', function() use ($app) {
	$user = $app['session']->get('user');
	if (empty($user)) { return false; }
	return $app->json(array(
			'id'     => intval($user['UserID']),
			'name'   => $user['Name'],
			'admin'  => !!$user['Admin'],
			'bought' => $user['Lessons']['Purchased'],
			'used'   => $user['Lessons']['Used'],
		));
});
$app->get('/account.html', function() use ($app, $render) {
	$user = $app['session']->get('user');
	if (empty($user)) { return $app->redirect('signin.html', 303); }
	$opts = array();
	$opts['variables'] = Controller\Account::getAccount(array( 'app'=>$app ));
	$opts['variables']['form'] = $app['session']->getFlashBag()->get('form')[0];
	$opts['variables']['messages'] = $app['session']->getFlashBag()->get('messages')[0];
	return $render('account', $opts);
});
$app->post('/account', function() use ($app) {
	$messages = Controller\Account::update(array( 'app'=>$app ), $app['request']->request->all());
	$app['session']->getFlashBag()->add('form', $app['request']->request->all());
	$app['session']->getFlashBag()->add('messages', $messages);
	return $app->redirect('account.html', 303);
});
$app->get('/terms.html', function() use ($app, $render) { return $render('terms'); });
$app->post('/terms', function() use ($app) {
	Controller\Account::acceptTerms(array( 'app'=>$app ), $app['request']->request->all());
	return $app->redirect('schedule.html', 303);
});
$app->get('/students/{userId}.json', function($userId) use ($app) {
	$params = array( 'app'=>$app, 'userId'=>$userId );
	$students = Controller\Account::getStudents($params);
	return $app->json($students, 200);
});

// Buy Lessons
$app->get('/purchase.html', function() use ($app, $render) {
	$user = $app['session']->get('user');
	if (empty($user)) { return $app->redirect('signin.html', 303); }
	$opts = array();
	$opts['variables'] = Controller\Account::getPurchaseItems(array( 'app'=>$app ));
	$opts['variables']['messages'] = $app['session']->getFlashBag()->get('messages')[0];
	return $render('purchase', $opts);
});
$app->post('/purchase', function() use ($app) {
	Controller\Account::purchaseIPN(array( 'app'=>$app ), $app['request']->request);
	return 'DONE';
});

// scheduling a lesson
$app->get('/schedule.html', function() use ($app, $render) {
	$user = $app['session']->get('user');
	if (empty($user)) { return $app->redirect('signin.html', 303); }
	if (!$user['AcceptTerms']) { return $app->redirect('terms.html', 303); }
	$user['Lessons'] = DB::getLessonCount($user);
	$app['session']->set('user', $user);
	return $render('schedule');
});
$app->get('/schedule/{location}/{year}-{month}.json', function($location, $year, $month) use ($app) {
	$params = array( 'app'=>$app, 'location'=>$location, 'year'=>$year, 'month'=>$month );
	$schedule = Controller\Schedule::getMonth($params);
	return $app->json($schedule, 200);
});
$app->post('/schedule/{location}/{date}/{teacher}.json', function($location, $date, $teacher) use ($app) {
	$params = array( 'app'=>$app, 'location'=>$location, 'date'=>$date, 'teacher'=>$teacher );
	$params['lesson'] = $app['request']->request->all();
	$lesson = Controller\Schedule::addLesson($params);
	return $app->json($lesson, 201);
});
$app->put('/schedule/{location}/{date}/{teacher}/{id}.json', function($location, $date, $teacher, $id) use ($app) {
	$params = array( 'app'=>$app, 'location'=>$location, 'date'=>$date, 'teacher'=>$teacher, 'id'=>$id );
	$params['lesson'] = $app['request']->request->all();
	$lesson = Controller\Schedule::updateLesson($params);
	return $app->json($lesson, 200);
});
$app->delete('/schedule/{location}/{date}/{teacher}/{id}.json', function($location, $date, $teacher, $id) use ($app) {
	$params = array( 'app'=>$app, 'location'=>$location, 'date'=>$date, 'teacher'=>$teacher, 'id'=>$id );
	Controller\Schedule::deleteLesson($params);
	return $app->json(null, 204);
});

// run the app
$app->run();
