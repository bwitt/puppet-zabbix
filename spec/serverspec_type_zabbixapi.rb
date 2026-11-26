# frozen_string_literal: true

require 'json'

module Serverspec::Type
  class Zabbixapi < Base
    def initialize(host, user, pass, method, params)
      @name   = 'zabbixapi'
      @host   = host
      @user   = user
      @pass   = pass
      @method = method
      @params = params
      @runner = Specinfra::Runner
      @curl_base = "curl -s http://#{host}/api_jsonrpc.php -H 'Content-Type: application/json-rpc'"
    end

    # The query runs lazily, so the type can be used in describe blocks
    def result
      @response ||= query(@method, @params)
      @response['result']
    end

    private

    def token
      @token ||= retrieve_token
    end

    def retrieve_token
      data = {
        jsonrpc: '2.0',
        method: 'user.login',
        params: {
          username: @user,
          password: @pass,
        },
        id: 0,
      }.to_json
      do_request(data)['result']
    end

    # apiinfo.version must be called without authentication
    def query(method, params)
      data = {
        jsonrpc: '2.0',
        method: method,
        params: params,
        id: 0,
      }.to_json
      do_request(data, (method == 'apiinfo.version') ? nil : token)
    end

    def do_request(data, auth = nil)
      header = auth.nil? ? '' : " -H 'Authorization: Bearer #{auth}'"
      command = "#{@curl_base}#{header} -d '#{data}'"
      result = @runner.run_command(command)
      JSON.parse(result.stdout.chomp)
    end
  end

  def zabbixapi(host, user, pass, method, params)
    Zabbixapi.new(host, user, pass, method, params)
  end
end
include Serverspec::Type
