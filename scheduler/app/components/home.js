/** @jsx React.DOM */

var React = require('react');
var Router = require('react-router');
var RouteHandler = Router.RouteHandler;

var Home = module.exports = React.createClass({
  render: function() {
    return (
      <div>
        <RouteHandler/>
      </div>
    )
  }
});