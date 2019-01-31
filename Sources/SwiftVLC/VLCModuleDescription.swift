//
//  VLCModuleDescription.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/31.
//

import CVLC

typealias CVLCModuleDescription = CVLC.libvlc_module_description_t

/// Description of a module.
public struct VLCModuleDescription {
  public let name: String
  public let shortname: String
  public let longname: String
  public let help: String?

  init(cDescription: libvlc_module_description_t) {
    self.name = String(cString: cDescription.psz_name)
    self.shortname = String(cString: cDescription.psz_shortname)
    self.longname = String(cString: cDescription.psz_longname)
    self.help = String(cString: cDescription.psz_help)
  }
}

extension VLCModuleDescription: CustomStringConvertible {

  public var description: String {
    return "\(name) - \(longname): \(help ?? "")"
  }
}

/// Event manager that belongs to a libvlc object, and from whom events can be received.
public final class VLCEventManagers {}
