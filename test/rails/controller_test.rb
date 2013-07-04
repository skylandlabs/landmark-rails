require 'test_helper'

class ControllerTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Rails.application.routes.url_helpers
  
  def script
    html = Nokogiri::HTML(@response.body)
    return html.css("script").last.to_s
  end

  test 'each request should clear Landmark tracking' do
    expected = <<-BLOCK.unindent.chomp
      <script>
      landmark.push("track", "/", {});
      </script>
    BLOCK

    get root_path
    assert_equal(expected, script)
    get root_path
    assert_equal(expected, script)
  end

  test 'authenticated users should automatically be identified' do
    expected = <<-BLOCK.unindent.chomp
      <script>
      landmark.push("identify", "123", {});
      landmark.push("track", "/authenticated", {});
      </script>
    BLOCK

    get "/authenticated"
    assert_equal(expected, script)
  end
end