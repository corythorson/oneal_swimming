/** @jsx React.DOM */

var React = require('react');
var Router = require('react-router');
var Routes = Router.Routes;
var Route = Router.Route;
var DefaultRoute = Router.DefaultRoute;
var moment = require('moment');

var App = require('./app');
var Home = require('./components/home');
var Scheduler = require('./components/scheduler');
var Schedule = require('./components/schedule');

//var RedirectToDefaultValue = React.createClass({
//  statics: {
//    willTransitionTo (transition, params) {
//      var today = moment().format('YYYY-MM-DD');
//      transition.redirect(`/s/${today}`);
//    }
//  },
//  render () { return null; }
//});

var routes = (
  <Route handler={App} path="/">
    <DefaultRoute handler={Scheduler} />
    <Route name="scheduler" path="/" handler={Scheduler} />
    <Route name="schedule" path="/assign" handler={Schedule} />
  </Route>
);

Router.run(routes, Router.HashLocation, function (Handler) {
  React.render(<Handler/>, document.getElementById('scheduler-app'));
});