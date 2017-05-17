USE [MillionSongDataset];
GO

-- Population was already performed, so we'll just
-- walk through the schema
CREATE TABLE UniqueSong (
	SongId VARCHAR(50)
	,SongTitle VARCHAR(500)
	,ArtistName VARCHAR(500)
	) AS Node;
GO

INSERT UniqueSong (SongId, SongTitle, ArtistName)
SELECT DISTINCT SongId, SongTitle, ArtistName
FROM unique_tracks;
GO

CREATE TABLE UniqueUser (UserId VARCHAR(80)) AS NODE;
GO

INSERT UniqueUser (UserId)
SELECT DISTINCT UserId 
FROM dbo.train_triplets;
GO

CREATE TABLE Likes (ListenCount BIGINT) AS EDGE;
GO

INSERT Likes ($from_id, $to_id, ListenCount)
SELECT U.$node_id, S.$node_id, T.ListenCount
FROM dbo.train_triplets AS T
INNER JOIN UniqueUser AS U ON U.UserId = T.UserId
INNER JOIN  UniqueSong AS S ON T.SongId = S.SongId;
GO


-- let's sample the data now
SELECT TOP 10 * FROM UniqueUser
SELECT TOP 10 * FROM UniqueSong
SELECT TOP 10 * FROM Likes

-----------------------------------------------------------------------------
-- *********************************************************************** --
-----------------------------------------------------------------------------
-- Similar songs
SELECT TOP 10 SimilarSong.SongTitle, COUNT(*)
FROM	UniqueSong AS MySong, 
		UniqueSong AS SimilarSong,
		UniqueUser,
		Likes AS LikesOther,
		Likes AS LikesThis
WHERE	MySong.SongTitle LIKE '%Just Dance%' AND
		MATCH(SimilarSong<-(LikesOther)-UniqueUser-(LikesThis)->MySong)
GROUP BY SimilarSong.SongTitle
ORDER BY COUNT(*) DESC;

SELECT TOP 10 SimilarSong.SongTitle, COUNT(*)
FROM	UniqueSong AS MySong, 
		UniqueSong AS SimilarSong,
		UniqueUser,
		Likes AS LikesOther,
		Likes AS LikesThis
WHERE	MySong.SongTitle LIKE '%Just Dance%' AND
		MATCH(UniqueUser-(LikesThis)->MySong) AND
		MATCH(UniqueUser-(LikesOther)->SimilarSong) 
GROUP BY SimilarSong.SongTitle
ORDER BY COUNT(*) DESC;

SELECT TOP 10 SimilarSong.SongTitle, COUNT(*)
FROM	UniqueSong AS MySong, 
		UniqueSong AS SimilarSong,
		UniqueUser,
		Likes AS LikesOther,
		Likes AS LikesThis
WHERE	MySong.SongTitle LIKE '%Just Dance%' AND
		MATCH(UniqueUser-(LikesThis)->MySong AND UniqueUser-(LikesOther)->SimilarSong)
GROUP BY SimilarSong.SongTitle
ORDER BY COUNT(*) DESC;


-- Similar artists 
SELECT TOP 10 SimilarSong.ArtistName, COUNT(*)
FROM	UniqueSong AS MySong, 
		UniqueUser,
		Likes AS LikesOther,
		Likes AS LikesThis,
		UniqueSong AS SimilarSong
WHERE	MySong.ArtistName = 'The Clash'AND 
		MATCH(SimilarSong<-(LikesOther)-UniqueUser-(LikesThis)->MySong)
GROUP BY SimilarSong.ArtistName
ORDER BY COUNT(*) DESC;
GO

-- Using SQL Server R Services to render graph images
EXEC sp_execute_external_script @language = N'R',
@script = N'
require(igraph)

g <- graph.data.frame(graphdf)

V(g)$label.cex <- 2

png(filename = "c:\\temp\\plot3.png", height = 6000, width = 6000, res = 100);
plot(g, vertex.label.family = "sans", vertex.size = 5)
dev.off()
',
@input_data_1 = N'select distinct LEFT(UserId, 5) as UserId, LEFT(REPLACE(ArtistName, '' '', ''''), 15) as ArtistName
            from 
            (
            select TOP 500 U.UserId, SimilarSong.ArtistName, ROW_NUMBER() OVER(PARTITION BY UserId ORDER BY LikesOther.ListenCount desc) as RowNum
            from UniqueSong as MySong, 
            UniqueUser as U,
            Likes as LikesOther,
            Likes as LikesThis,
            UniqueSong as SimilarSong
            where MySong.SongTitle = ''Should I Stay or Should I Go''
            and MATCH(SimilarSong<-(LikesOther)-U-(LikesThis)->MySong)
            ) as InnerTable
            where RowNum <= 20
            order by UserId',
@input_data_1_name = N'graphdf';