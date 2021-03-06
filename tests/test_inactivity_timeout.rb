require_relative 'em_test_helper'

class TestInactivityTimeout < Test::Unit::TestCase

  if EM.respond_to? :get_comm_inactivity_timeout
    def test_default
      EM.run {
        c = EM.connect("127.0.0.1", 54321)
        assert_equal 0.0, c.comm_inactivity_timeout
        EM.stop
      }
    end

    def test_set_and_get
      EM.run {
        c = EM.connect("127.0.0.1", 54321)
        c.comm_inactivity_timeout = 2.5
        assert_equal 2.5, c.comm_inactivity_timeout
        EM.stop
      }
    end

    def test_for_real
      start, finish = nil

      timeout_start = Module.new do
        define_method :post_init do
          start = Time.now
        end
      end

      timeout_handler = Module.new do
        define_method :unbind do
          finish = Time.now
          EM.stop
        end
      end

      EM.run {
        setup_timeout 0.4
        EM.heartbeat_interval = 0.01
        EM.start_server("127.0.0.1", 12345, timeout_start)
        EM.add_timer(0.01) {
          c = EM.connect("127.0.0.1", 12345, timeout_handler)
          c.comm_inactivity_timeout = 0.02
        }
      }
      # Travis can vary from 0.02 to 0.17, Appveyor maybe as low as 0.01
      assert_in_delta(0.09, (finish - start), 0.08)
    end
  else
    warn "EM.comm_inactivity_timeout not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_comm_inactivity_timeout_not_implemented
      assert true
    end
  end
end
