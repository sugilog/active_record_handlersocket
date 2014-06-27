module WarningHelper
  def fake_warning_log
    @warn_log = StringIO.new
    $stderr   = @warn_log
  end

  def reset_warning_log
    $stderr   = STDERR
    @warn_log = nil
  end

  def warning_log
    @warn_log
  end
end
