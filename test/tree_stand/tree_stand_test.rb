# frozen_string_literal: true

require 'test_helper'

class TreeStandTest < Minitest::Test
  def test_everything_is_documented
    report = `bundle exec yard stats --list-undoc`
    documented = report.lines.detect { |line| line =~ /% documented/ }

    assert_equal('100.00% documented', documented.strip, report)
  end
end
