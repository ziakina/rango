# encoding: utf-8

# http://wiki.github.com/botanicus/rango/controllers

require "rango/router"
require "rango/exceptions"
require "rango/rack/request"

module Rango
  class Controller
    # [master] Change Merb::Controller to respond to #call and return a Rack Array. (wycats)http://rubyurl.com/BhoY
    # @since 0.0.2
    def self.call(env)
      Rango::Router.set_rack_env(env)
      request = Rango::Request.new(env)
      options = env["rango.router.params"] || raise("rango.router.params property has to be setup at least to empty hash")
      method = env["rango.controller.action"].to_sym
      controller = self.new(env, options.merge(request.params))
      begin
        unless controller.respond_to?(method) # TODO: what about method_missing?
          raise NotFound, "Controller #{self.name} doesn't have method #{method}"
        end
        controller.run_filters(:before, method.to_sym)
        # If you don't care about arguments or if you prefer usage of params.
        if controller.method(method).arity.eql?(0)
          Rango.logger.debug("Calling method #{self.name}##{method} without arguments")
          controller.response.body = controller.method(method).call
        else
          args = controller.params.values
          Rango.logger.debug("Calling method #{self.name}##{method} with arguments #{args.inspect}")
          controller.response.body = controller.method(method).call(*args)
        end
        controller.run_filters(:after, method)
        return controller.response.finish
      rescue HttpError => exception
        controller.rescue_http_error(exception)
      end
    end

    # for routers
    def self.dispatcher(action)
      lambda do |env|
        Rango.logger.info("Dispatching to #{self}##{action} [#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}]")
        env["rango.controller.action"] = action
        return self.call(env)
      end
    end

    # @since 0.0.1
    # @return [RubyExts::Logger] Logger for logging project related stuff.
    # @see RubyExts::Logger
    attribute :logger, Rango.logger
    attribute :status
    attribute :headers, Hash.new

    # @since 0.0.1
    # @return [Rango::Request]
    # @see Rango::Request
    attr_accessor :request, :params, :cookies, :response
    # @since 0.0.1
    # @return [Hash] Hash with params from request. For example <code>{messages: {success: "You're logged in"}, post: {id: 2}}</code>
    attr_accessor :params

    # @since 0.0.2
    def redirect(url, options = Hash.new)
      self.status = 302
      self.headers["Location"] = URI.escape(url)
      return String.new
    end

    def initialize(env, params = Hash.new)
      @request  = Rango::Request.new(env)
      @response = Rack::Response.new
      @params   = params
      @cookies  = request.cookies
      @session  = request.session
      Rango.logger.inspect(params: params, cookies: cookies, session: session)
    end
    attr_reader :session

    # redefine this method for your controller if you want to provide custom error pages
    # returns response array for rack
    # if you need to change just body of error message, define render_http_error method
    # @api plugin
    def rescue_http_error(exception)
      status, headers, body = exception.to_response
      if self.respond_to?(:render_http_error)
        [status, headers, self.render_http_error(exception)]
      else
        [status, headers, body]
      end
    end
  end
end
