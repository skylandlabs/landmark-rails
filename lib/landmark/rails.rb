require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/notifications'

module Landmark
  module Rails
    ############################################################################
    #
    # Attributes
    #
    ############################################################################

    # The current user identifier for this request.
    mattr_reader :user_id

    # A list traits for the current user in this request.
    mattr_reader :traits

    # A list of events performed by the user in this request.
    mattr_reader :events

    # The parsed configuration file found at config/landmark.yml
    def self.config
      @config ||= YAML.load_file("#{::Rails.root}/config/landmark.yml")[::Rails.env] rescue {}
    end
    
    # Retrieves the API key set for the environment.
    def self.api_key
      @api_key ||= config['api_key']
    end

    # The configuration setting for if paths that are automatically tracked are normalized.
    def self.normalize_paths?
      if @normalize_paths.nil?
        @normalize_paths = config['normalize_paths']
        @normalize_paths = true if @normalize_paths.nil?
      end
      return @normalize_paths
    end


    ############################################################################
    #
    # Static Methods
    #
    ############################################################################

    ####################################
    # Identify / Track
    ####################################

    # Identifies the current user in the request.
    def self.identify(user_id, traits={})
      @@user_id = user_id
      @@traits = traits
    end

    # Tracks an action performed by the user.
    def self.track(action, properties={})
      @@events ||= []
      @@events << {action:action, properties:properties}
      @@user_id = user_id
      @@traits = traits
    end


    ####################################
    # Utility
    ####################################

    # Normalizes a path to remove numeric sections.
    def self.normalize_path(path)
      return path.to_s.gsub(/\/(\d+|\d+-[^\/]+)(?=\/|$)/, "/-")
    end

    # Clears all identification and tracking. This is called every time that
    # a request is started.
    def self.clear()
      @@user_id = nil
      @@traits = nil
      @@events = nil
    end


    ####################################
    # JavaScript
    ####################################

    # The JavaScript code generated by identification and tracking calls for
    # the current request.
    def self.javascript_tag()
      str = javascript_prologue_tag + 
      "<script>\n" +
      javascript_initialize_script +
      javascript_identify_script +
      javascript_track_script +
      "</script>\n"

      return str.html_safe
    end

    # The prologue tags that setup and load the remote Landmark JavaScript.
    def self.javascript_prologue_tag()
      "<script>window.landmark=[];</script>\n" +
      "<script src=\"https://landmark.io/landmark.js\"></script>\n"
    end

    # The initialize() JavaScript script generated to set the API key.
    def self.javascript_initialize_script()
      return "landmark.push(\"initialize\", #{Landmark::Rails.api_key.to_json});\n"
    end

    # The identify() JavaScript script generated if the user has been identified.
    def self.javascript_identify_script()
      if user_id.nil?
        return ""
      else
        return "landmark.push(\"identify\", #{user_id.to_s.to_json}, #{traits.to_json});\n"
      end
    end

    # The track() JavaScript script generated if one or more tracking calls
    # have been made.
    def self.javascript_track_script()
      @@events.to_a.map do |event|
        "landmark.push(\"track\", #{event[:action].to_s.to_json}, #{event[:properties].to_json});\n"
      end.join("")
    end
  end
end

require 'landmark/rails/controller'
require 'landmark/rails/notifications'
require 'landmark/rails/version'