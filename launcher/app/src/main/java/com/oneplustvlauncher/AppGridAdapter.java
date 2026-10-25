package com.oneplustvlauncher;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.oneplustvlauncher.utils.AppInfo;

import java.util.List;

public class AppGridAdapter extends RecyclerView.Adapter<AppGridAdapter.VH> {

    public interface OnFocusListener {
        void onAppFocused(AppInfo app, View itemView);
    }

    public interface OnClickListener {
        void onAppClicked(AppInfo app);
    }

    private final List<AppInfo> mApps;
    private OnFocusListener mFocusListener;
    private OnClickListener mClickListener;

    public AppGridAdapter(List<AppInfo> apps) {
        this.mApps = apps;
    }

    public void setFocusListener(OnFocusListener l) { mFocusListener = l; }
    public void setClickListener(OnClickListener l) { mClickListener = l; }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_app_tile, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        AppInfo app = mApps.get(position);
        holder.banner.setImageDrawable(app.banner);
        holder.name.setText(app.label);

        holder.itemView.setOnFocusChangeListener((v, hasFocus) -> {
            if (hasFocus) {
                holder.itemView.animate().scaleX(1.12f).scaleY(1.12f).setDuration(150).start();
                holder.name.setVisibility(View.VISIBLE);
                if (mFocusListener != null) mFocusListener.onAppFocused(app, holder.itemView);
            } else {
                holder.itemView.animate().scaleX(1f).scaleY(1f).setDuration(150).start();
                holder.name.setVisibility(View.INVISIBLE);
            }
        });

        holder.itemView.setOnClickListener(v -> {
            if (mClickListener != null) mClickListener.onAppClicked(app);
        });
    }

    @Override
    public int getItemCount() { return mApps.size(); }

    static class VH extends RecyclerView.ViewHolder {
        ImageView banner;
        TextView name;
        VH(@NonNull View v) {
            super(v);
            banner = v.findViewById(R.id.app_banner);
            name = v.findViewById(R.id.app_name);
        }
    }
}
