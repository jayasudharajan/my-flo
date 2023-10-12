package com.flo.pureconfig

import pureconfig.{ConfigReader, ConfigWriter, Exported}
import pureconfig.generic.ExportMacros

trait AutoDerivation {
  implicit def exportReader[A]: Exported[ConfigReader[A]] = macro ExportMacros.exportDerivedReader[A]
  implicit def exportWriter[A]: Exported[ConfigWriter[A]] = macro ExportMacros.exportDerivedWriter[A]
}
