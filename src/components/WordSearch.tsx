function WordSearch() {
  return (
    <div className="word-search-container">
      <div className="word-search-header">
        <div className="word-search-title">
          <h1>Word Search Game</h1>
          <p>Total Score: {totalScore}</p>
        </div>
      </div>

      <div className="word-search-game">
        <div className="word-search-grid">
          {/* ... existing grid code ... */}
        </div>

        <div className="word-search-sidebar">
          <div className="word-list">
            <h3>Words to Find:</h3>
            {/* ... existing words to find code ... */}
          </div>

          <div className="found-words">
            <h3>Found Words:</h3>
            {/* Remove the 'Found this round' counter but keep the list of found words */}
            {foundWords.map((word, index) => (
              <p key={index}>{word}</p>
            ))}
          </div>
        </div>
      </div>

      {/* ... existing code ... */}
    </div>
  );
} 