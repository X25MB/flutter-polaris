package agersant.polaris.api.remote;

import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;

import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.upstream.DefaultDataSource;

import java.io.File;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisService;

import static android.os.AsyncTask.Status.FINISHED;


class DownloadQueueWorkItem {

	private final File scratchFile;
	private final PolarisService service;
	private CollectionItem item;
	private DownloadTask job;
	private MediaSource mediaSource;
	private DefaultDataSource dataSource;

	DownloadQueueWorkItem(File scratchFile, PolarisService service) {
		this.scratchFile = scratchFile;
		this.service = service;
	}

	boolean hasMediaSourceFor(CollectionItem item) {
		return this.item != null && this.item.getPath().equals(item.getPath());
	}

	boolean isDownloading(CollectionItem item) {
		if (this.item == null || job == null) {
			return false;
		}
		boolean correctItem = this.item.getPath().equals(item.getPath());
		return correctItem && job.getStatus() != FINISHED;
	}

	boolean isIdle() {
		if (job != null) {
			AsyncTask.Status status = job.getStatus();
			switch (status) {
				case PENDING:
				case RUNNING:
					return false;
			}
		}
		return isDataSourceIdle();
	}

	private boolean isDataSourceIdle() {
		return mediaSource == null || !service.isUsing(mediaSource);
	}

	boolean canBeInterrupted() {
		return isDataSourceIdle();
	}

	void assignItem(CollectionItem item) {
		reset();
		this.item = item;
		Uri uri = service.getServerAPI().serveUri(item.getPath());
		PolarisExoPlayerDataSourceFactory dsf = new PolarisExoPlayerDataSourceFactory(service, scratchFile, item);
		mediaSource = new ExtractorMediaSource(uri, dsf, new DefaultExtractorsFactory(), null, null);
		dataSource = dsf.createDataSource();
		broadcast(DownloadQueue.WORKLOAD_CHANGED);
	}

	MediaSource getMediaSource() {
		return mediaSource;
	}

	void beginBackgroundDownload() {
		System.out.println("Beginning background download for: " + item.getPath());
		Uri uri = service.getServerAPI().serveUri(item.getPath());
		job = new DownloadTask(dataSource, uri);
		job.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
		broadcast(DownloadQueue.WORKLOAD_CHANGED);
	}

	void stopBackgroundDownload() {
		job.cancel(false);
		job = null;
		broadcast(DownloadQueue.WORKLOAD_CHANGED);
	}

	private void reset() {
		if (mediaSource != null) {
			mediaSource.releaseSource();
			mediaSource = null;
		}
		if (dataSource != null) {
			dataSource = null;
		}
		if (job != null) {
			job.cancel(false);
			job = null;
		}
		item = null;
	}

	private void broadcast(@SuppressWarnings("SameParameterValue") String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

}
