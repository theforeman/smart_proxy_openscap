require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_lib'

class SpoolForwarderTest < Test::Unit::TestCase
  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @base_spool_for_test = ("#{Dir.getwd}/test/data/spool")
    @results_path = ("#{Dir.getwd}/test/test_run_files")
    FileUtils.mkdir_p(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:contentdir).returns(@results_path)
    @spooldir = @results_path + "/spool"
    Proxy::OpenSCAP::Plugin.settings.stubs(:spooldir).returns(@spooldir)
    Proxy::OpenSCAP::Plugin.settings.stubs(:reportsdir).returns(@results_path + "/reports")
    Proxy::OpenSCAP::Plugin.settings.stubs(:corrupted_dir).returns(@results_path + "/corrupted")
    @policy_id = 1
    @date_1 = 1484309984
    @date_2 = 1484313035
    @id_1 = 42
    @id_2 = 84
    @valid_digest = "fa2f68ffb944c917332a284dc63ec7f8fa76990cb815ddcad3318b5d9457f8a1"
    @corrupted_digest = "a4dfba5db27b21795e6fa401b8dce7a70faeb25b7963891f07f6f4baaf052afb"
    @cname = "e20b9695-f655-401a-9dda-8cca7a47a8c0"
    @cname_2 = "2c101b95-033f-4b15-b490-f50bf9090dae"

    @arf_dir = File.join(Proxy::OpenSCAP::Plugin.settings.spooldir, "/arf")

    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date_1}")
      .to_return(:status => 200, :body => "{\"result\":\"OK\",\"id\":\"#{@id_1}\"}")

    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date_2}")
      .to_return(:status => 200, :body => "{\"result\":\"OK\",\"id\":\"#{@id_2}\"}")

  end

  def teardown
    FileUtils.rm_rf @results_path
  end

  def test_send_spool_to_foreman
    test_spool = @base_spool_for_test + "/valid_spool/"
    FileUtils.cp_r test_spool, @spooldir

    Proxy::OpenSCAP::SpoolForwarder.new.post_arf_from_spool(@arf_dir)
    assert(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@id_1}/#{@date_1}/#{@valid_digest}"), "File should be in reports directory")
    assert(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@id_2}/#{@date_2}/#{@valid_digest}"), "File should be in reports directory")
    refute(File.file?("#{@spooldir}/arf/#{@cname}/#{@policy_id}/#{@date_1}/#{@valid_digest}"), "File should not be in spool directory")
    refute(File.file?("#{@spooldir}/arf/#{@cname}/#{@policy_id}/#{@date_2}/#{@valid_digest}"), "File should not be in spool directory")
  end

  def test_send_corrupted_spool_to_foreman
    test_spool = @base_spool_for_test + "/corrupted_spool/"
    FileUtils.cp_r test_spool, @spooldir

    Proxy::OpenSCAP::SpoolForwarder.new.post_arf_from_spool(@arf_dir)

    assert(File.file?("#{@results_path}/corrupted/arf/#{@cname}/#{@policy_id}/#{@date_1}/#{@corrupted_digest}"), "File should be in corrupted directory")
    assert(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@id_2}/#{@date_2}/#{@valid_digest}"), "File should be in reports directory")

    refute(File.file?("#{@spooldir}/arf/#{@cname}/#{@policy_id}/#{@date_1}/#{@corrupted_digest}"), "File should not be in spool directory")
    refute(File.file?("#{@spooldir}/arf/#{@cname}/#{@policy_id}/#{@date_2}/#{@valid_digest}"), "File should not be in spool directory")
  end

  def test_send_spool_cleans_up
    test_spool = @base_spool_for_test + "/cleanup_spool/"
    FileUtils.cp_r test_spool, @spooldir

    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date_1}")
      .to_return(:status => 200, :body => "{\"result\":\"OK\",\"id\":\"#{@id_1}\"}")

    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname_2}/#{@policy_id}/#{@date_2}")
      .to_return(:status => 500)

    Proxy::OpenSCAP::SpoolForwarder.new.post_arf_from_spool(@arf_dir)

    assert(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@id_1}/#{@date_1}/#{@valid_digest}"), "File should be in reports directory")
    assert(File.file?("#{@spooldir}/arf/#{@cname_2}/#{@policy_id}/#{@date_2}/#{@valid_digest}"), "File should be in spool directory")

    refute(File.exist?("#{@spooldir}/arf/#{@cname}"), "Folder should not exist")
  end
end
