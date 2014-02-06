# encoding: UTF-8
require 'test_helper'

class MeasureTest < ActiveSupport::TestCase

  test "instanciation" do
    assert_nothing_raised do
      Measure.new(55.23, "kilogram")
    end
    assert_nothing_raised do
      Measure.new(55.23, :kilogram)
    end
    assert_nothing_raised do
      Measure.new("55.23 kilogram")
    end
    assert_nothing_raised do
      Measure.new("55.23kilogram")
    end
    assert_nothing_raised do
      Measure.new("55.23 kg")
    end
    assert_nothing_raised do
      Measure.new("55.23kg")
    end
    assert_nothing_raised do
      55.23.in_kilogram
    end
    assert_nothing_raised do
      55.23.in(:kilogram)
    end
    assert_nothing_raised do
      55.23.in("kilogram")
    end
  end

  test "conversions" do
    m = 1452.218534748545.in_ton
    assert_equal m.to_f, 1452.218534748545
    assert_equal m.to_d, 1452.218534748545
    assert_equal m.to_r, 1452.218534748545
  end


  test "operations" do
    m1 = 155.in_kilogram
    m2 = 1.045.in_ton

    assert_equal m1.unit, "kilogram"
    assert_equal m1.value, 155
    assert_equal m2.unit, "ton"
    assert_equal m2.value, 1.045
    # Test equality with conversion
    assert_equal m1, 0.155.in_ton
    assert_equal m2, 1.045.in_ton
    assert_equal 1045.in_kilogram, m2.in_kilogram
    # Checks that value is not impacted by previous conversion
    # due to a possible side effect
    assert_equal m2.unit, "ton"
    assert_equal m2.value, 1.045
    assert_equal m2, 1.045.in_ton

    assert_raise IncompatibleDimensions do
      (m2 != 1.045.in_square_meter)
    end

    assert_raise IncompatibleDimensions do
      (m2 == 1.045.in_square_meter)
    end

    assert m1 != m2
    assert m1 < m2
    assert m2 > m1
    assert m1 <= m2
    assert m2 >= m1

    m3 = nil
    assert_nothing_raised do
      m3 = m1 + m2
    end
    assert_equal m3, 1.2.in_ton
    assert_equal m3, 1200.in_kilogram
    assert_equal m3, 1200000.in_gram

    assert_equal m3/2, 600.in_kilogram
    assert_equal m3*2, 2400.in_kilogram
    assert_equal m3*2.to_f, 2400.in_kilogram
    assert_equal m3*2.to_d, 2400.in_kilogram
    assert_equal m3*2.to_r, 2400.in_kilogram

    m4 = 1.2.in_cubic_meter

    assert_raise IncompatibleDimensions do
      m4 + m2
    end
  end

end
