//
//  VLCError.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/31.
//

import CVLC

public struct VLCError: Error, Equatable {
  public let code: Int32

  public init(code: Int32) {
    self.code = code
  }
}

extension VLCError: CustomStringConvertible {

  public var description: String {
    return String(cString: libvlc_errmsg()) ?? ""
  }
}

func abortIfFail(_ code: Int32, function: String) {
  if code != 0 {
    fatalError("\(function): \(String(cString: libvlc_errmsg()) ?? "")")
  }
}

func throwIfFail(_ code: Int32, predicate: (Int32) -> Bool = { $0 < 0 }) throws {
  if predicate(code) {
    throw VLCError(code: code)
  }
}
