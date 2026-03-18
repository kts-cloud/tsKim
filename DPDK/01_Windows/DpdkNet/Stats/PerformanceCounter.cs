using System.Diagnostics;

namespace HwNet.Stats
{
    public class PerformanceCounter
    {
        private long _txPackets;
        private long _rxPackets;
        private long _txBytes;
        private long _rxBytes;
        private long _errors;
        private long _dropped;

        private long _prevTxPackets;
        private long _prevRxPackets;
        private long _prevTxBytes;
        private long _prevRxBytes;

        private readonly Stopwatch _sw = new();
        private double _lastElapsed;

        public double PeakTxPps { get; private set; }
        public double PeakRxPps { get; private set; }
        public double PeakTxMbps { get; private set; }
        public double PeakRxMbps { get; private set; }

        public double ElapsedSeconds => _sw.Elapsed.TotalSeconds;

        public void Start()
        {
            _sw.Restart();
            _lastElapsed = 0;
        }

        public void Reset()
        {
            Interlocked.Exchange(ref _txPackets, 0);
            Interlocked.Exchange(ref _rxPackets, 0);
            Interlocked.Exchange(ref _txBytes, 0);
            Interlocked.Exchange(ref _rxBytes, 0);
            Interlocked.Exchange(ref _errors, 0);
            Interlocked.Exchange(ref _dropped, 0);
            _prevTxPackets = 0;
            _prevRxPackets = 0;
            _prevTxBytes = 0;
            _prevRxBytes = 0;
            PeakTxPps = 0;
            PeakRxPps = 0;
            PeakTxMbps = 0;
            PeakRxMbps = 0;
            _sw.Restart();
            _lastElapsed = 0;
        }

        public void AddTx(long packets, long bytes)
        {
            Interlocked.Add(ref _txPackets, packets);
            Interlocked.Add(ref _txBytes, bytes);
        }

        public void AddRx(long packets, long bytes)
        {
            Interlocked.Add(ref _rxPackets, packets);
            Interlocked.Add(ref _rxBytes, bytes);
        }

        public void AddErrors(long count) => Interlocked.Add(ref _errors, count);
        public void AddDropped(long count) => Interlocked.Add(ref _dropped, count);

        public StatsSnapshot TakeSnapshot()
        {
            double now = _sw.Elapsed.TotalSeconds;
            double interval = now - _lastElapsed;
            if (interval <= 0) interval = 1.0;

            long txPkts = Interlocked.Read(ref _txPackets);
            long rxPkts = Interlocked.Read(ref _rxPackets);
            long txByt = Interlocked.Read(ref _txBytes);
            long rxByt = Interlocked.Read(ref _rxBytes);

            double txPps = (txPkts - _prevTxPackets) / interval;
            double rxPps = (rxPkts - _prevRxPackets) / interval;
            double txMbps = (txByt - _prevTxBytes) * 8.0 / interval / 1_000_000;
            double rxMbps = (rxByt - _prevRxBytes) * 8.0 / interval / 1_000_000;

            if (txPps > PeakTxPps) PeakTxPps = txPps;
            if (rxPps > PeakRxPps) PeakRxPps = rxPps;
            if (txMbps > PeakTxMbps) PeakTxMbps = txMbps;
            if (rxMbps > PeakRxMbps) PeakRxMbps = rxMbps;

            _prevTxPackets = txPkts;
            _prevRxPackets = rxPkts;
            _prevTxBytes = txByt;
            _prevRxBytes = rxByt;
            _lastElapsed = now;

            return new StatsSnapshot
            {
                Timestamp = DateTime.Now,
                TxPackets = txPkts,
                RxPackets = rxPkts,
                TxBytes = txByt,
                RxBytes = rxByt,
                TxPps = txPps,
                RxPps = rxPps,
                TxMbps = txMbps,
                RxMbps = rxMbps,
                Errors = Interlocked.Read(ref _errors),
                Dropped = Interlocked.Read(ref _dropped)
            };
        }
    }
}
