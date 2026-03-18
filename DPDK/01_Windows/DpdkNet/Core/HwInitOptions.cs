namespace HwNet
{
    public class HwInitOptions
    {
        public string CoreMask { get; set; } = "0";
        public int MemoryMb { get; set; } = 512;
        public string LogLevel { get; set; } = "*:error";
        public ushort PortId { get; set; } = 0;
        public uint MbufPoolSize { get; set; } = 8191;
        public uint LinkSpeeds { get; set; } = 0;

        /// <summary>
        /// EAL --file-prefix. 서로 다른 프로세스가 동시에 DPDK를 사용할 때
        /// hugepage 파일 충돌을 방지합니다. null이면 기본 prefix 사용.
        /// </summary>
        public string? FilePrefix { get; set; }
    }
}
