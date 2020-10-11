import os
import json
import sequtils
import strutils
import sugar

import nimPNG


type Config = object
  width: int
  height: int
  step: int
  colors: seq[seq[byte]]


func isEvenPosition(position: int, width: int): bool =
  (position div width + position mod width) mod 2 == 0


func isEvenStep(position: int, width: int, step: int): bool =
  ((position div width) div step + (position mod width) div step) mod 2 == 0


proc main(
  outputPath = os.joinPath(os.getCurrentDir(), "output.png"),
  configPath = os.joinPath(os.getCurrentDir(), "config.json")
): cint =
  echo "output: ", outputPath, ", config: ", configPath

  if not os.existsFile(configPath):
    return 1

  let configJSON = json.parseFile(configPath)
  echo configJSON.pretty()

  let colors =
    configJSON["colors"].getElems()
      .map(col => col.getStr()[1..<col.getStr().len()])
      .map(col => @[
        strutils.fromHex[byte](col[0..1]),
        strutils.fromHex[byte](col[2..3]),
        strutils.fromHex[byte](col[4..5])
      ])

  let config =
    Config(
      width: configJSON["width"].getInt(),
      height: configJSON["height"].getInt(),
      step: configJSON["step"].getInt(),
      colors: colors
    )
  echo config

  let pixels = config.width * config.height
  
  var image: seq[seq[byte]] = newSeq[seq[byte]](pixels)
  for i in 0..<pixels:
    if not isEvenPosition(i, config.width) and not isEvenStep(i, config.width, config.step):
      image[i] = config.colors[0]
    elif isEvenPosition(i, config.width):
      image[i] = config.colors[1]
    elif not isEvenPosition(i, config.width) and isEvenStep(i, config.width, config.step):
      image[i] = config.colors[2]
    else:
      echo "Calculation is something wrong"
      return 1

  let imageData: seq[byte] = image.concat()
  let status = nimPNG.savePNG24(outputPath, imageData, config.width, config.height)

  if status.isOk():
    echo "Saved ", outputPath
  elif status.isErr():
    echo "Did not save ", outputPath
    echo status 
    return 1

  return 0


when isMainModule:
  import cligen
  cligen.dispatch(main)
