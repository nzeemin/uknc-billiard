using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;
using System.Linq;
using System.Text;
// ReSharper disable IdentifierTypo

namespace SpriteRotate
{
    class Program
    {
        static void Main(string[] args)
        {
            PrepareSpritesText();
            //PrepareFont();
        }

        static byte[] PrepareSpriteArray(Bitmap bmp, int x, int y, int cols, int rows)
        {
            var octets = new byte[cols * rows];
            {
                for (int row = 0; row < rows; row++)
                {
                    for (int col = 0; col < cols; col++)
                    {
                        int val = 0;
                        for (int b = 0; b < 8; b++)
                        {
                            Color c = bmp.GetPixel(x + col * 8 + b, y + row);
                            int v = (c.GetBrightness() > 0.5f) ? 0 : 1;
                            val |= (v << b);
                        }

                        octets[row * cols + col] = (byte)val;
                    }
                }
            }

            return octets;
        }

        static void WriteByteArray(byte[] octets, StreamWriter writer)
        {
            int cnt = 0;
            for (int i = 0; i < octets.Length; i++)
            {
                if (cnt == 0)
                {
                    writer.Write("\t.BYTE ");
                }
                else
                {
                    writer.Write(",");
                }

                writer.Write(EncodeOctalString(octets[i]));

                cnt++;
                if (cnt >= 16)
                {
                    writer.WriteLine();
                    cnt = 0;
                }
            }
            if (cnt != 0)
                writer.WriteLine();
        }

        static void PrepareSprite(Bitmap bmp, int x, int y, int cols, int rows, StreamWriter writer)
        {
            var octets = PrepareSpriteArray(bmp, x, y, cols, rows);
            WriteByteArray(octets, writer);
        }

        static void PrepareSpritesText()
        {
            var bmp = new Bitmap(@"..\balls.png");

            using (var writer = new StreamWriter("SPRITE.MAC"))
            {
                writer.WriteLine("BALLS:");
                for (int i = 0; i < 8; i++)
                {
                    writer.Write($"BALL{i}:");
                    PrepareSprite(bmp, i * 25, 9, 3, 19, writer);
                }
                writer.WriteLine("\t.EVEN");

                writer.WriteLine("FONTD9:");
                for (int i = 0; i < 10; i++)
                {
                    PrepareSprite(bmp, i * 9, 34, 1, 9, writer);
                }
                writer.WriteLine("\t.EVEN");

                Console.WriteLine("SPRITE.MAC saved");
            }
        }

        static string EncodeOctalString(byte value)
        {
            //convert to int, for cleaner syntax below. 
            int x = (int)value;

            return string.Format(
                @"{0}{1}{2}",
                ((x >> 6) & 7),
                ((x >> 3) & 7),
                (x & 7)
            );
        }

        static string EncodeOctalString2(int x)
        {
            return string.Format(
                @"{0}{1}{2}{3}{4}{5}",
                ((x >> 15) & 7),
                ((x >> 12) & 7),
                ((x >> 9) & 7),
                ((x >> 6) & 7),
                ((x >> 3) & 7),
                (x & 7)
            );
        }
    }
}
