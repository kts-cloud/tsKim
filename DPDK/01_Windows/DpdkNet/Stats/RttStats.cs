namespace HwNet.Stats
{
    public class RttStats
    {
        private long _sent;
        private long _received;
        private long _timeouts;
        private long _rxOther;
        private long _minRttBits = BitConverter.DoubleToInt64Bits(double.MaxValue);
        private long _maxRttBits = BitConverter.DoubleToInt64Bits(0.0);
        private long _totalRttBits = BitConverter.DoubleToInt64Bits(0.0);
        private long _totalRttSqBits = BitConverter.DoubleToInt64Bits(0.0);

        public long Sent => Interlocked.Read(ref _sent);
        public long Received => Interlocked.Read(ref _received);
        public long Timeouts => Interlocked.Read(ref _timeouts);
        public long RxOther => Interlocked.Read(ref _rxOther);

        public double MinRtt
        {
            get
            {
                long r = Interlocked.Read(ref _received);
                return r > 0 ? BitConverter.Int64BitsToDouble(Interlocked.Read(ref _minRttBits)) : 0;
            }
        }
        public double MaxRtt => BitConverter.Int64BitsToDouble(Interlocked.Read(ref _maxRttBits));
        public double AvgRtt
        {
            get
            {
                long r = Interlocked.Read(ref _received);
                return r > 0 ? BitConverter.Int64BitsToDouble(Interlocked.Read(ref _totalRttBits)) / r : 0;
            }
        }

        public double StdDevRtt
        {
            get
            {
                long r = Interlocked.Read(ref _received);
                if (r < 2) return 0;
                double mean = BitConverter.Int64BitsToDouble(Interlocked.Read(ref _totalRttBits)) / r;
                double meanSq = BitConverter.Int64BitsToDouble(Interlocked.Read(ref _totalRttSqBits)) / r;
                double variance = meanSq - mean * mean;
                return variance > 0 ? Math.Sqrt(variance) : 0;
            }
        }

        public void AddSent() => Interlocked.Increment(ref _sent);

        public void AddReceived(double rttMs)
        {
            Interlocked.Increment(ref _received);

            long rttBits = BitConverter.DoubleToInt64Bits(rttMs);
            long oldBits, newBits;

            // Accumulate sum
            do
            {
                oldBits = Interlocked.Read(ref _totalRttBits);
                double newVal = BitConverter.Int64BitsToDouble(oldBits) + rttMs;
                newBits = BitConverter.DoubleToInt64Bits(newVal);
            } while (Interlocked.CompareExchange(ref _totalRttBits, newBits, oldBits) != oldBits);

            // Accumulate sum of squares (for StdDev)
            double rttSq = rttMs * rttMs;
            do
            {
                oldBits = Interlocked.Read(ref _totalRttSqBits);
                double newVal = BitConverter.Int64BitsToDouble(oldBits) + rttSq;
                newBits = BitConverter.DoubleToInt64Bits(newVal);
            } while (Interlocked.CompareExchange(ref _totalRttSqBits, newBits, oldBits) != oldBits);

            // Update min
            do
            {
                oldBits = Interlocked.Read(ref _minRttBits);
                if (rttMs >= BitConverter.Int64BitsToDouble(oldBits)) break;
                newBits = rttBits;
            } while (Interlocked.CompareExchange(ref _minRttBits, newBits, oldBits) != oldBits);

            // Update max
            do
            {
                oldBits = Interlocked.Read(ref _maxRttBits);
                if (rttMs <= BitConverter.Int64BitsToDouble(oldBits)) break;
                newBits = rttBits;
            } while (Interlocked.CompareExchange(ref _maxRttBits, newBits, oldBits) != oldBits);
        }

        /// <summary>
        /// Bulk-add batch results without per-item loop overhead.
        /// totalRttMs = sum of all RTT values, totalRttSqMs = sum of RTT² values.
        /// </summary>
        public void AddBatch(int sent, int received, int timeouts,
            double totalRttMs, double totalRttSqMs, double minRtt, double maxRtt)
        {
            Interlocked.Add(ref _sent, sent);
            Interlocked.Add(ref _received, received);
            Interlocked.Add(ref _timeouts, timeouts);

            if (received <= 0) return;

            long oldBits, newBits;

            // Accumulate sum
            do
            {
                oldBits = Interlocked.Read(ref _totalRttBits);
                newBits = BitConverter.DoubleToInt64Bits(BitConverter.Int64BitsToDouble(oldBits) + totalRttMs);
            } while (Interlocked.CompareExchange(ref _totalRttBits, newBits, oldBits) != oldBits);

            // Accumulate sum of squares
            do
            {
                oldBits = Interlocked.Read(ref _totalRttSqBits);
                newBits = BitConverter.DoubleToInt64Bits(BitConverter.Int64BitsToDouble(oldBits) + totalRttSqMs);
            } while (Interlocked.CompareExchange(ref _totalRttSqBits, newBits, oldBits) != oldBits);

            // Update min
            long minBits = BitConverter.DoubleToInt64Bits(minRtt);
            do
            {
                oldBits = Interlocked.Read(ref _minRttBits);
                if (minRtt >= BitConverter.Int64BitsToDouble(oldBits)) break;
            } while (Interlocked.CompareExchange(ref _minRttBits, minBits, oldBits) != oldBits);

            // Update max
            long maxBits = BitConverter.DoubleToInt64Bits(maxRtt);
            do
            {
                oldBits = Interlocked.Read(ref _maxRttBits);
                if (maxRtt <= BitConverter.Int64BitsToDouble(oldBits)) break;
            } while (Interlocked.CompareExchange(ref _maxRttBits, maxBits, oldBits) != oldBits);
        }

        public void AddTimeout() => Interlocked.Increment(ref _timeouts);
        public void AddRxOther() => Interlocked.Increment(ref _rxOther);

        public void Reset()
        {
            Interlocked.Exchange(ref _sent, 0);
            Interlocked.Exchange(ref _received, 0);
            Interlocked.Exchange(ref _timeouts, 0);
            Interlocked.Exchange(ref _rxOther, 0);
            Interlocked.Exchange(ref _minRttBits, BitConverter.DoubleToInt64Bits(double.MaxValue));
            Interlocked.Exchange(ref _maxRttBits, BitConverter.DoubleToInt64Bits(0.0));
            Interlocked.Exchange(ref _totalRttBits, BitConverter.DoubleToInt64Bits(0.0));
            Interlocked.Exchange(ref _totalRttSqBits, BitConverter.DoubleToInt64Bits(0.0));
        }
    }
}
