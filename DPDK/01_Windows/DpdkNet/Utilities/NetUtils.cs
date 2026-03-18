using System.Net;

namespace HwNet.Utilities
{
    public static class NetUtils
    {
        public static ushort Htons(ushort v) => (ushort)(((v & 0xff) << 8) | ((v >> 8) & 0xff));
        public static ushort Ntohs(ushort v) => Htons(v);

        public static uint Htonl(uint v) =>
            ((v & 0x000000ff) << 24) |
            ((v & 0x0000ff00) << 8) |
            ((v & 0x00ff0000) >> 8) |
            ((v & 0xff000000) >> 24);
        public static uint Ntohl(uint v) => Htonl(v);

        public static uint IpToUint(string ip)
        {
            byte[] bytes = IPAddress.Parse(ip).GetAddressBytes();
            return (uint)(bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24));
        }

        public static string UintToIp(uint ip)
        {
            return $"{ip & 0xFF}.{(ip >> 8) & 0xFF}.{(ip >> 16) & 0xFF}.{(ip >> 24) & 0xFF}";
        }

        public static byte[] ParseMac(string mac)
        {
            string[] parts = mac.Split(':', '-');
            if (parts.Length != 6)
                throw new FormatException($"Invalid MAC: {mac}");
            byte[] result = new byte[6];
            for (int i = 0; i < 6; i++)
                result[i] = Convert.ToByte(parts[i], 16);
            return result;
        }

        public static string FormatMac(byte[] mac)
        {
            if (mac == null || mac.Length < 6) return "??:??:??:??:??:??";
            return $"{mac[0]:X2}:{mac[1]:X2}:{mac[2]:X2}:{mac[3]:X2}:{mac[4]:X2}:{mac[5]:X2}";
        }

        public static ushort ComputeIpChecksum(byte[] header)
        {
            uint sum = 0;
            for (int i = 0; i < header.Length; i += 2)
            {
                ushort word = (ushort)((header[i] << 8) | (i + 1 < header.Length ? header[i + 1] : 0));
                sum += word;
            }
            while ((sum >> 16) != 0)
                sum = (sum & 0xFFFF) + (sum >> 16);
            return (ushort)~sum;
        }

        public static ushort ComputeUdpChecksum(uint srcIp, uint dstIp, byte[] udpHeaderAndPayload)
        {
            uint sum = 0;

            byte[] srcBytes = BitConverter.GetBytes(srcIp);
            byte[] dstBytes = BitConverter.GetBytes(dstIp);
            sum += (uint)((srcBytes[0] << 8) | srcBytes[1]);
            sum += (uint)((srcBytes[2] << 8) | srcBytes[3]);
            sum += (uint)((dstBytes[0] << 8) | dstBytes[1]);
            sum += (uint)((dstBytes[2] << 8) | dstBytes[3]);
            sum += 17;
            sum += (uint)udpHeaderAndPayload.Length;

            for (int i = 0; i < udpHeaderAndPayload.Length; i += 2)
            {
                ushort word;
                if (i + 1 < udpHeaderAndPayload.Length)
                    word = (ushort)((udpHeaderAndPayload[i] << 8) | udpHeaderAndPayload[i + 1]);
                else
                    word = (ushort)(udpHeaderAndPayload[i] << 8);
                sum += word;
            }

            while ((sum >> 16) != 0)
                sum = (sum & 0xFFFF) + (sum >> 16);

            ushort result = (ushort)~sum;
            return result == 0 ? (ushort)0xFFFF : result;
        }
    }
}
