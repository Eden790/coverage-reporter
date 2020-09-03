require "crest"
require "json"
require "./config.cr"

module CoverageReporter
  class Api
    API_VERSION = "v1"

    def initialize(
        token : String,
        yaml : YamlConfig,
        git : Hash(Symbol, String | Hash(Symbol, String)),
        job_flag : String,
        source_files : Array(Hash(Symbol, Array(Int32 | Nil) | String))
    )
      @yaml = yaml
      @git = git
      @sauce = source_files || {} of String => Array(Int32)
      @general_config = Config.new(token, job_flag, @yaml)
    end

    def send_request
      data = build_request

      puts "🚀 Posting coverage data to #{uri}"

      res = Crest.post(
        uri,
        headers: { "Content-Type" => "application/json" },
        form: { :json => data.to_json.to_s }.to_json
      )

      # TODO: include info about account status
      puts "---\n✅ API Response: #{res.body}\n- 💛, Coveralls"

      nil
    end

    private def build_request
      @general_config.get_config.merge(
        {
          :source_files => @sauce,
          :git => @git,
        }
      )
    end

    private def uri
      if ENV["COVERALLS_ENDPOINT"]?
        host = ENV["COVERALLS_ENDPOINT"]?
        domain = ENV["COVERALLS_ENDPOINT"]?
      else
        host = ENV["COVERALLS_DEVELOPMENT"]? ? "localhost:3000" : "coveralls.io"
        protocol = ENV["COVERALLS_DEVELOPMENT"]? ? "http" : "https"
        domain = "#{protocol}://#{host}"
      end

      return "#{domain}/api/#{API_VERSION}/jobs"
    end
  end
end
