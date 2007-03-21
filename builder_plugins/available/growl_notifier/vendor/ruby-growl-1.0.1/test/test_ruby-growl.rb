#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'

require 'ruby-growl'

class TestGrowl < Test::Unit::TestCase

  def setup
    @growl = Growl.new "localhost", "ruby-growl test",
                       ["ruby-growl Test Notification"]
  end

  def test_notify_priority
    assert_raises RuntimeError do
      @growl.notify "ruby-growl Test Notification", "", "", -3
    end

    assert_nothing_raised do
      -2.upto 2 do |priority|
        @growl.notify "ruby-growl Test Notification",
                      "Priority #{priority}",
                      "This message should have a priority set.", priority
      end
    end

    assert_raises RuntimeError do
      @growl.notify "ruby-growl Test Notification", "", "", 3
    end
  end

  def test_notify_notify_type
    assert_raises RuntimeError do
      @growl.notify "bad notify type", "", ""
    end

    assert_nothing_raised do
      @growl.notify "ruby-growl Test Notification", "Empty", "This notification is empty."
    end
  end

  def test_notify_sticky
      @growl.notify "ruby-growl Test Notification", "Sticky",
                    "This notification should be sticky.", 0, true
  end

  def test_registration_packet
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "00", "00", "0b",  "01", "01", "67", "72", # ......gr
      "6f", "77", "6c", "6e",  "6f", "74", "69", "66", # owlnotif
      "79", "00", "1f", "43",  "6f", "6d", "6d", "61", # y..Comma
      "6e", "64", "2d", "4c",  "69", "6e", "65", "20", # nd-Line.
      "47", "72", "6f", "77",  "6c", "20", "4e", "6f", # Growl.No
      "74", "69", "66", "69",  "63", "61", "74", "69", # tificati
      "6f", "6e", "00", "57",  "4a", "e3", "1b", "a5", # on.WJ...
      "49", "9c", "25", "3a",  "be", "75", "5d", "e5", # I.%:.u].
      "2c", "c9", "96"                                 # ,..
    ]

    packet = @growl.registration_packet

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

  def test_notification_packet
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "01", "00", "00",  "00", "1f", "00", "00", # ........ 
      "00", "02", "00", "0b",  "43", "6f", "6d", "6d", # ....Comm
      "61", "6e", "64", "2d",  "4c", "69", "6e", "65", # and-Line
      "20", "47", "72", "6f",  "77", "6c", "20", "4e", # .Growl.N
      "6f", "74", "69", "66",  "69", "63", "61", "74", # otificat
      "69", "6f", "6e", "68",  "69", "67", "72", "6f", # ionhigro
      "77", "6c", "6e", "6f",  "74", "69", "66", "79", # wlnotify
      "7f", "9c", "a0", "dd",  "b6", "6b", "64", "75", # .....kdu
      "99", "c4", "4e", "7b",  "f1", "b2", "5b", "e2", # ..N{..[.
    ]

    packet = @growl.notification_packet "Command-Line Growl Notification",
                                        "", "hi", 0, false

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

  def test_notification_packet_priority_negative_2
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "01", "00", "0c",  "00", "1f", "00", "00", # ........ 
      "00", "02", "00", "0b",  "43", "6f", "6d", "6d", # ....Comm
      "61", "6e", "64", "2d",  "4c", "69", "6e", "65", # and-Line
      "20", "47", "72", "6f",  "77", "6c", "20", "4e", # .Growl.N
      "6f", "74", "69", "66",  "69", "63", "61", "74", # otificat
      "69", "6f", "6e", "68",  "69", "67", "72", "6f", # ionhigro
      "77", "6c", "6e", "6f",  "74", "69", "66", "79", # wlnotify
      "6d", "98", "51", "12",  "4f", "dc", "38", "4a",
      "b5", "eb", "9e", "f3",  "2d", "e0", "aa", "5e"
    ]

    packet = @growl.notification_packet "Command-Line Growl Notification",
                                        "", "hi", -2, false

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

  def test_notification_packet_priority_negative_1
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "01", "00", "0e",  "00", "1f", "00", "00", # ........ 
      "00", "02", "00", "0b",  "43", "6f", "6d", "6d", # ....Comm
      "61", "6e", "64", "2d",  "4c", "69", "6e", "65", # and-Line
      "20", "47", "72", "6f",  "77", "6c", "20", "4e", # .Growl.N
      "6f", "74", "69", "66",  "69", "63", "61", "74", # otificat
      "69", "6f", "6e", "68",  "69", "67", "72", "6f", # ionhigro
      "77", "6c", "6e", "6f",  "74", "69", "66", "79", # wlnotify
      "d2", "cc", "44", "30",  "21", "fa", "fd", "c6",
      "a8", "f3", "db", "72",  "2b", "64", "f4", "25"
    ]

    packet = @growl.notification_packet "Command-Line Growl Notification",
                                        "", "hi", -1, false

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

  def test_notification_packet_priority_1
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "01", "00", "02",  "00", "1f", "00", "00", # ........ 
      "00", "02", "00", "0b",  "43", "6f", "6d", "6d", # ....Comm
      "61", "6e", "64", "2d",  "4c", "69", "6e", "65", # and-Line
      "20", "47", "72", "6f",  "77", "6c", "20", "4e", # .Growl.N
      "6f", "74", "69", "66",  "69", "63", "61", "74", # otificat
      "69", "6f", "6e", "68",  "69", "67", "72", "6f", # ionhigro
      "77", "6c", "6e", "6f",  "74", "69", "66", "79", # wlnotify
      "bf", "de", "a5", "63",  "09", "29", "27", "02",
      "13", "1f", "8e", "5c",  "f1", "88", "f8", "93"
    ]

    packet = @growl.notification_packet "Command-Line Growl Notification",
                                        "", "hi", 1, false

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

  def test_notification_packet_priority_2
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "01", "00", "04",  "00", "1f", "00", "00", # ........ 
      "00", "02", "00", "0b",  "43", "6f", "6d", "6d", # ....Comm
      "61", "6e", "64", "2d",  "4c", "69", "6e", "65", # and-Line
      "20", "47", "72", "6f",  "77", "6c", "20", "4e", # .Growl.N
      "6f", "74", "69", "66",  "69", "63", "61", "74", # otificat
      "69", "6f", "6e", "68",  "69", "67", "72", "6f", # ionhigro
      "77", "6c", "6e", "6f",  "74", "69", "66", "79", # wlnotify
      "d5", "40", "af", "67",  "3c", "d3", "80", "eb",
      "3d", "46", "5d", "c3",  "75", "09", "24", "95"
    ]

    packet = @growl.notification_packet "Command-Line Growl Notification",
                                        "", "hi", 2, false

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

  def test_notification_packet_priority_sticky
    @growl = Growl.new "localhost", "growlnotify",
                       ["Command-Line Growl Notification"]

    expected = [
      "01", "01", "00", "01",  "00", "1f", "00", "00", # ........ 
      "00", "02", "00", "0b",  "43", "6f", "6d", "6d", # ....Comm
      "61", "6e", "64", "2d",  "4c", "69", "6e", "65", # and-Line
      "20", "47", "72", "6f",  "77", "6c", "20", "4e", # .Growl.N
      "6f", "74", "69", "66",  "69", "63", "61", "74", # otificat
      "69", "6f", "6e", "68",  "69", "67", "72", "6f", # ionhigro
      "77", "6c", "6e", "6f",  "74", "69", "66", "79", # wlnotify
      "eb", "75", "2a", "36",  "85", "6c", "d7", "a2",
      "72", "0b", "13", "6b",  "41", "c7", "ea", "1b"
    ]

    packet = @growl.notification_packet "Command-Line Growl Notification",
                                        "", "hi", 0, true

    packet = packet.split(//).map { |char| "%02x" % char[0] }

    assert_equal expected, packet
  end

end

