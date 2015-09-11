/** @jsx React.DOM */

var React = require('react');
var Router = require('react-router');
var RouteHandler = Router.RouteHandler;

var App = module.exports = React.createClass({
  render: function() {
    return (
      <div className='App'>
        <RouteHandler/>
      </div>
    )
  }
});