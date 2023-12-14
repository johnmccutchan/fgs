package com.example.fgs;

import java.util.Random;
import android.graphics.Color;

public class Utils {
  private static int index = 0;
  private static int[] colors = {
    0xffdd1dfa,
    0xff286add,
    0xffedab41,
    0xff3d6d6b,
    0xff86536c,
    0xff37f2e8,
    0xff719adc,
    0xff384e22,
    0xff313741,
    0xff52cbbe,
    0xffb73ff7,
    0xff751626,
    0xff5e0f59,
    0xff58b726,
    0xff49fe20,
    0xffd45a6c,
    0xff6a8224,
    0xffa72ced,
    0xffc983a1,
    0xff1e1fd0,
    0xff7c593b,
    0xff48646b,
    0xff40f7ae,
    0xffea38e3,
    0xff421a55,
    0xff3c877e,
    0xffdaeec9,
    0xff3af74f,
    0xffb2b0c9,
    0xfff1f627,
    0xff9d6f28,
    0xff634901
  };
  static int getRandomColor() {
    index = (index + 1) % colors.length;
    return colors[index];
  }
}
