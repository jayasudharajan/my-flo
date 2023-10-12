import com.flo.Enums.Locale.TemperatureUnitSystemAbbreviation


def convertTemperatureFromUSImperial(convertTo: String, fahrenheit: BigDecimal): BigDecimal = convertTo match {
  case TemperatureUnitSystemAbbreviation.CELSIUS =>
    fahrenheit.-(32).*(5)./(9)
  case _ => fahrenheit
}



convertTemperatureFromUSImperial(TemperatureUnitSystemAbbreviation.CELSIUS,BigDecimal("90.0"))


