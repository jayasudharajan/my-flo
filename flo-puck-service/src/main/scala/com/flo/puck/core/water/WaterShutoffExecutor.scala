package com.flo.puck.core.water

import com.flo.puck.core.api._
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class WaterShutoffExecutor(
  sendShutoffDeviceAction: ShutoffDevice,
  getDeviceById: GetDeviceById,
  sendDeviceShutoffAlert: DeviceIncidentSender
)(implicit ec: ExecutionContext) extends ShutoffExecutor {

  override def apply(actionRules: List[ActionRule]): Future[Unit] = {

    val devicesToShutoff = actionRules.filter(ar => ar.enabled && ar.action == ShutOff && ar.event == WaterDetected)

    val eventualAction = Future.traverse(devicesToShutoff) { d =>
      processDevice(d.targetDeviceId)
    }

    eventualAction.failed.foreach { e =>
      throw new RuntimeException(p"Error processing Device Shutoff.", e)
    }

    eventualAction.map(_ => ())
  }

  private def processDevice(deviceId: DeviceId): Future[Unit] = {
    val eventualDevice = getDeviceById(deviceId)

    eventualDevice.failed.foreach { e =>
      throw new RuntimeException(p"Error retrieving Device with id $deviceId from Api gateway" , e)
    }

    eventualDevice.flatMap { device =>
      if (device.isConnected && device.isValveOpen)
        shutoffDevice(device)
      else
        Future.unit
    }
  }

  private def shutoffDevice(device: Device): Future[Unit] = {
    sendShutoffDeviceAction(device.id).flatMap { _ =>
      sendDeviceShutoffAlert(device)
    }
  }
}